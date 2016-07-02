/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Drt
{

public class MessageChannel: GLib.Object, Diorite.MessageListener
{
	static const uint32 HEADER_MASK = (uint32) (1 << 31);
	static const uint32 MAX_ID = (uint32) ~(1 << 31);
	static const bool REQUEST = false;
	static const bool RESPONSE = true;
	
	public uint id {get; construct;}
	public Drt.DuplexChannel channel {get; construct;}
	public bool pending {get; private set; default = false;}
	public bool closed {get; protected set; default = false;}
	public string name {get{return channel.name;}}
	public MessageRouter router {get; protected set;}
	private static bool log_comunication;
	private uint last_message_id = 0;
	private bool send_pending = false;
	private bool processing_pending = false;
	private HashTable<void*, Message?> incoming_requests;
	private HashTable<void*, Message?> outgoing_requests;
	private Queue<Message> incoming_queue;
	private Queue<Message> outgoing_queue;
	private GenericSet<void*> allowed_errors;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_SERVER") == "yes";
	}
	
	public MessageChannel.from_name(uint id, string name, MessageRouter? router, uint timeout=500) throws Diorite.IOError
	{
		var path = Diorite.Ipc.create_path(name);
		try
		{
			var address = new UnixSocketAddress(path);
			var socket =  new Socket(SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
			var connection = SocketConnection.factory_create_connection(socket);
			connection.connect(address, null);
			this(id, new Diorite.SocketChannel(path, connection), router);
		}
		catch (GLib.Error e)
		{
			throw new Diorite.IOError.CONN_FAILED("Failed to connect to socket '%s'. %s", path, e.message);
		}
	}
	
	public MessageChannel(uint id, Drt.DuplexChannel channel, MessageRouter? router)
	{
		GLib.Object(id: id, channel: channel, router: router ?? new HandlerRouter(null));
	}
	
	construct
	{
		incoming_requests = new HashTable<void*, Message?>(direct_hash, direct_equal);
		outgoing_requests = new HashTable<void*, Message?>(direct_hash, direct_equal);
		incoming_queue = new Queue<Message>();
		outgoing_queue = new Queue<Message>();
		allowed_errors = new GenericSet<void*>(null, null);
		allow_error_propagation(new Diorite.MessageError.UNKNOWN("").domain);
		allow_error_propagation(new Drt.ApiError.UNKNOWN("").domain);
		
		channel.bind_property(
			"closed", this, "closed", BindingFlags.DEFAULT|BindingFlags.SYNC_CREATE);
		start_receiving();
	}
	
	
	
	public void allow_error_propagation(Quark error_quark)
	{
		allowed_errors.add(((uint) error_quark).to_pointer());
	}
	
	public bool is_error_allowed(Quark error_quark)
	{
		return allowed_errors.contains(((uint) error_quark).to_pointer());
	}
	
	/**
	 * Convenience wrapper around send_message_async() that waits in main loop
	 * and then returns result.
	 */
	public Variant? send_message(string name, Variant? params=null) throws GLib.Error
	{
		var loop = new MainLoop();
		var id = queue_request(name, params, loop.quit);
		loop.run();
		return get_response(id);
	}
	
	public async Variant? send_message_async(string name, Variant? params=null) throws GLib.Error
	{
		var id = queue_request(name, params, (RequestCallback) send_message_async.callback);
		yield;
		return get_response(id);
	}
	
	public bool close()
	{
		var result = true;
		try
		{
			channel.close();
		}
		catch (GLib.IOError e)
		{
			warning("Failed to close channel '%s': [%d] %s", name, e.code, e.message);
			result = false;
		}
		
		if (closed == false)
			closed = true;
		return result;
	}
	
	private uint queue_request(string name, Variant? params, owned RequestCallback callback)
	{
		Message msg;
		lock (last_message_id)
		{
			lock (outgoing_requests)
			{
				uint id = last_message_id;
				do
				{
					if (id == MAX_ID)
						id = 1;
					else
						id++;
				}
				while (outgoing_requests.contains(id.to_pointer()));
				last_message_id = id;
				msg = new Message(id, REQUEST, name, params, (owned) callback);
				outgoing_requests[id.to_pointer()] = msg;
			}
		}
		lock (outgoing_queue)
		{
			outgoing_queue.push_tail(msg);
		}
		start_sending();
		return msg.id;
	}
	
	/**
	 * Start asynchronous sending of queued outgoing messages.
	 */
	private void start_sending()
	{
		lock (send_pending)
		{
			if (send_pending)
				return;
			send_pending = true;
		}
		send_messages.begin(on_send_messages_done);
	}
	
	/**
	 * Callback when sending of queued outgoing messages has been finished.
	 */
	private void on_send_messages_done(GLib.Object? o, AsyncResult result)
	{
		send_messages.end(result);
		lock (send_pending)
		{
			send_pending = false;
		}
	}
	
	/**
	 * Asynchronous loop sending queued outgoing messages.
	 */
	private async void send_messages()
	{
		while (true)
		{
			Message? msg = null;
			lock (outgoing_queue)
			{
				msg = outgoing_queue.pop_head();
			}
			if (msg == null)
				break;
			yield send(msg);
		}
	}
	
	/**
	 * Send a single message
	 * 
	 * @param msg   message to send
	 */
	private async void send(Message msg)
	{
		if (log_comunication)
			debug("Channel(%u) %s(%u): Send  %s => %s",
				this.id, msg.direction == REQUEST ? "Request": "Response",
				msg.id, msg.label, msg.data != null ? msg.data.print(false) : "null");
		
		var buffer = Diorite.serialize_message(msg.label, msg.data, (uint) sizeof(uint32));
		write_header(ref buffer, 0, msg.direction, msg.id);
		var payload = new ByteArray.take((owned) buffer);
		GLib.Error? error = null;
		try
		{
			yield channel.write_bytes_async(payload);
		}
		catch (Diorite.IOError e)
		{
			warning("Channel(%u) %s(%u): Failed to send. %s",
					this.id, msg.direction == REQUEST ? "Request": "Response",
					msg.id, e.message);
			error = e;
		}
		
		if (msg.direction == REQUEST)
		{
			if (error != null)
				process_response(msg, null, null, error);
		}
		else // RESPONSE
		{
			lock (incoming_requests)
			{
				incoming_requests.remove(msg.id.to_pointer());
			}
		}
	}
	
	protected void check_closed()
	{
//~ 		warning(@"Is connected $(channel.connection.is_connected()), closed $(channel.connection.closed)");
	}
	
	/**
	 * Return response for given message id
	 * 
	 * @param id    Message id
	 * @return response data
	 * @throw local or remote errors arisen from the request
	 */
	private Variant? get_response(uint id) throws GLib.Error
	{
		bool found;
		Message? msg;
		lock (outgoing_requests)
		{
			msg = outgoing_requests.take(id.to_pointer(), out found);
		}
		assert(found);
		if (msg.error != null)
			throw msg.error;
		return msg.data;
	}
	
	/**
	 * Returns maximal message size
	 * 
	 * @return maximal message size
	 */
	public static size_t get_max_message_size()
	{
		return DuplexChannel.get_max_message_size() - sizeof(uint32);
	}
	
	/**
	 * Start asynchronous loop to receive messages
	 */
	private void start_receiving()
	{
		receive_messages.begin(on_receive_messages_done);
	}
	
	/**
	 * Callback when receiving messages has been finished.
	 */
	private void on_receive_messages_done(GLib.Object? o, AsyncResult result)
	{
		receive_messages.end(result);
	}
	
	/**
	 * Asynchronous loop receiving incoming requests or responses.
	 */
	private async void receive_messages()
	{
		while (!closed)
		{
			try
			{
				yield receive();
			}
			catch (Diorite.IOError e)
			{
				warning("Channel(%u) IOError while receiving data: %s", this.id, e.message);
				close();
				break;
			}
		}
	}
	
	/**
	 * Receive a single message
	 * 
	 * @throw Diorite.IOError on unrecoverable read failure
	 */
	private async void receive() throws Diorite.IOError
	{
		Message msg = null;
		ByteArray data = null;
		yield channel.read_bytes_async(out data, 0, null); // throws Diorite.IOError
		
		var bytes = ByteArray.free_to_bytes((owned) data);
		var buffer = Bytes.unref_to_data((owned) bytes);
		bool direction;
		uint id;
		read_header(buffer, 0, out direction, out id);
		
		string? label = null;
		Variant? params = null;
		GLib.Error? error = null;
		if (!Diorite.deserialize_message((owned) buffer, out label, out params, (uint) sizeof(uint32)))
			error = new Diorite.MessageError.INVALID_RESPONSE("Server returned invalid response. Cannot deserialize message.");
		
		if (log_comunication)
			debug("Channel(%u) %s(%u): Received  %s => %s",
				this.id, direction == REQUEST ? "Request": "Response",
				id, label, params != null ? params.print(false) : "null");
		
		if (direction == REQUEST)
		{
			
			msg = new Message(id, direction, label, params, null);
			lock (incoming_requests)
			{
				incoming_requests[id.to_pointer()] = msg;
			}
			lock (incoming_queue)
			{
				incoming_queue.push_tail(msg);
			}
			start_processing_requests();
		}
		else // RESPONSE
		{
			lock (outgoing_requests)
			{
				msg = outgoing_requests[id.to_pointer()];
			}
			if (msg == null)
			{
				warning("Channel(%u) %s(%u): Received, but this response is unexpected. %s => %s",
					this.id, direction == REQUEST ? "Request": "Response",
					id, label, params != null ? params.print(false) : "null");
			}
			else
			{
				process_response(msg, label, params, error);
			}
		}
	}
	
	/**
	 * Process response to request and call its callback
	 * 
	 * @param msg      request message
	 * @param label    response label
	 * @param data     response data
	 * @param error    response errot
	 */
	private void process_response(Message msg, string? label, Variant? data, GLib.Error? error)
	{
		msg.label = null;
		if (error != null)
		{
			msg.data = null;
			if (!is_error_allowed(error.domain))
				msg.error = new Diorite.MessageError.UNKNOWN("Server returned unknown error (%s).", error.domain.to_string());
			else
				msg.error = error;
		}
		else if (label == Diorite.Ipc.RESPONSE_OK)
		{
			msg.data = data;
			msg.error = null;
		}
		else if (label == Diorite.Ipc.RESPONSE_ERROR)
		{
			msg.data = null;
			if (data == null)
			{
				msg.error = new Diorite.MessageError.INVALID_RESPONSE("Server returned empty error.");
			}
			else
			{
				var e = Diorite.deserialize_error(data);
				if (e == null)
					msg.error = new Diorite.MessageError.UNKNOWN("Server returned unknown error.");
				else if (!is_error_allowed(e.domain))
					msg.error = new Diorite.MessageError.UNKNOWN("Server returned unknown error (%s).", e.domain.to_string());
				else
					msg.error = e;
			}
		}
		else
		{
			msg.data = null;
			msg.error = new Diorite.MessageError.INVALID_RESPONSE("Server returned invalid response status '%s'.", label);
		}
		Idle.add(msg.idle_callback);
	}
	
	/**
	 * Start asynchronous loop to process incoming requests
	 */
	private void start_processing_requests()
	{
		lock (processing_pending)
		{
			if (processing_pending)
				return;
			processing_pending = true;
		}
		process_requests.begin(on_process_requests_done);
	}
	
	/**
	 * Callback when processing incoming requests has been finished.
	 */
	private void on_process_requests_done(GLib.Object? o, AsyncResult result)
	{
		process_requests.end(result);
		lock (processing_pending)
		{
			processing_pending = false;
		}
	}
	
	/**
	 * Asynchronous loop processing incoming requests.
	 */
	private async void process_requests()
	{
		while (true)
		{
			Idle.add(process_requests.callback);
			yield;
			Message? msg = null;
			lock (incoming_queue)
			{
				msg = incoming_queue.pop_head();
			}
			if (msg == null)
				break;
			
			string status;
			Variant? response;
			handle_request(msg.label, msg.data, out status, out response);
			msg.direction = RESPONSE;
			msg.label = (owned) status;
			msg.data = response;
			lock (outgoing_queue)
			{
				outgoing_queue.push_tail(msg);
			}
			start_sending();
		}
	}
	
	/**
	 * Handle incoming request
	 * 
	 * This method is similar to `handle_message`, but it uses `status` and `response` to indicate
	 * success/failure instead of throwing error.
	 *  
	 * @param name        request name
	 * @param params      request parameters
	 * @param status      response status
	 * @param response    response data
	 * @return true if request has been handled successfully
	 */
	protected virtual bool handle_request(string name, Variant? params, out string status, out Variant? response)
	{
		try 
		{
			response = router.handle_message(this, name, params);
			status = Diorite.Ipc.RESPONSE_OK;
		}
		catch (GLib.Error e)
		{
			status = Diorite.Ipc.RESPONSE_ERROR;
			if (!is_error_allowed(e.domain))
				response = Diorite.serialize_error(
					new Diorite.MessageError.UNKNOWN("Server returned unknown error (%s).", e.domain.to_string()));
			else
				response = Diorite.serialize_error(e);
		}
		return true;
	}	
	
	/**
	 * Read header to extract message direction and id
	 * 
	 * @param buffer       message data buffer
	 * @param offset       offset at which the header starts
	 * @param direction    message direction: `RESPONSE` or `REQUEST`
	 * @param id           message id
	 */
	void read_header(uint8[] buffer, uint offset, out bool direction, out uint id)
	{
		uint32 header;
		Diorite.uint32_from_bytes(buffer, out header, offset);
		direction = (header & HEADER_MASK) != 0 ? RESPONSE : REQUEST;
		id = (uint)(header & ~HEADER_MASK);
	}
	
	/**
	 * Write header to add message direction and id
	 * 
	 * @param buffer       message data buffer
	 * @param offset       offset at which the header will be written
	 * @param direction    message direction: `RESPONSE` or `REQUEST`
	 * @param id           message id
	 */
	void write_header(ref uint8[] buffer, uint offset, bool direction, uint id)
	{
		uint32 header = ((uint32) id) | (direction == RESPONSE ? HEADER_MASK : 0);
		Diorite.uint32_to_bytes(ref buffer, header, offset);
	}
	
	/**
	 * Called when a response to the request is received
	 */
	private delegate void RequestCallback();
	
	public void add_handler(string message_name, string? type_string, owned Diorite.MessageHandler handler)
	{
		router.add_handler(message_name, type_string, (owned) handler);
	}
	
	public bool remove_handler(string message_name)
	{
		return router.remove_handler(message_name);
	}
	
	private class Message
	{
		public uint id;
		public bool direction;
		public string? label;
		public Variant? data = null;
		public GLib.Error? error = null;
		public RequestCallback? callback = null;
		
		public Message(uint id, bool direction, string label, Variant? data, owned RequestCallback? callback)
		{
			this.id = id;
			this.direction = direction;
			this.label = label;
			this.data = data;
			this.callback = (owned) callback;
		}
		
		public bool idle_callback()
		{
			this.callback();
			return false;
		}
	}
}

} // namespace Drt
