/*
 * Copyright 2014-2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

#if LINUX

namespace Drt
{

public abstract class DuplexChannel: GLib.Object
{
	private static const bool REQUEST = false;
	private static const bool RESPONSE = true;
	private static const uint32 HEADER_MASK = (uint32) (1 << 31);
	private static const uint32 MAX_ID = (uint32) ~(1 << 31);
	private static const int MESSAGE_BUFSIZE = 512;
	private static bool log_comunication;
	private static bool timeout_fatal;
	public uint id {get; private set;}
	public string name {get; private set;}
	public bool closed {get; protected set; default = false;}
	public uint timeout {get; set;}
	public InputStream input {get; private set;}
	public OutputStream output {get; private set;}
	private HashTable<void*, Payload?> outgoing_requests;
	private AsyncQueue<Payload?> outgoing_queue;
	private uint last_payload_id = 0;
	private Thread<void*>? writer_thread = null;
	private Thread<void*>? reader_thread = null;
	
	
	public DuplexChannel(uint id, string name, InputStream input, OutputStream output, uint timeout)
	{
		this.id = id;
		this.name = name;
		this.output = output;
		this.input = input;
		this.timeout = timeout;
	}
	
	construct
	{
		outgoing_requests = new HashTable<void*, Payload?>(direct_hash, direct_equal);
		outgoing_queue = new AsyncQueue<Payload?>();
		notify["closed"].connect_after(on_closed_changed);
	}	
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_DUPLEX_CHANNEL") == "yes";
		timeout_fatal = Environment.get_variable("DIORITE_DUPLEX_CHANNEL_FATAL_TIMEOUT") == "yes";
	}
		
	/**
	 * Start sending and receiving messages.
	 */
	public void start()
	{
		if (reader_thread == null)
			reader_thread = new Thread<void*>("Ch%u".printf(this.id), reader_thread_func);
		if (writer_thread == null)
			writer_thread = new Thread<void*>("Ch%u".printf(this.id), writer_thread_func);
	}
	
	/**
	 * Send a request through the channel and wait for a response.
	 * 
	 * @param data    The data to send.
	 * @return The data received as a response.
	 * @throw GLib.Error on failure.
	 */
	public ByteArray? send_request(ByteArray? data=null) throws GLib.Error
	{
		check_not_closed_or_error();
		var loop = new MainLoop();
		var id = queue_request(data, loop.quit);
		loop.run();
		return get_response(id);
	}
	
	/**
	 * Send a request through the channel and return a response asynchronously.
	 * 
	 * @param data    The data to send.
	 * @return The data received as a response.
	 * @throw GLib.Error on failure.
	 */
	public async ByteArray? send_request_async(ByteArray? data=null) throws GLib.Error
	{
		check_not_closed_or_error();
		var id = queue_request(data, (RequestCallback) send_request_async.callback);
		yield;
		return get_response(id);
	}
	
	/**
	 * Send a response to a previously received request.
	 * 
	 * @param id      The id of a previously received request.
	 * @param data    The response to send.
	 * @throws GLib.Error on failure, e.g. if the channel is closed.
	 */
	public void send_response(uint id, ByteArray? data) throws GLib.Error
	{
		check_not_closed_or_error();
		var payload = new Payload(id, RESPONSE, data, null);
		outgoing_queue.push(payload);
	}
	
	public virtual void close() throws GLib.IOError
	{
		closed = true;
		GLib.IOError? err = null;
		try
		{
			input.close();
		}
		catch (GLib.IOError e)
		{
			err = e;
		}
		try
		{
			output.close();
		}
		catch (GLib.IOError e)
		{
			if (err == null)
				err = e;
		}
		if (err != null)
			throw err;
	}
	
	/**
	 * Emitted when a new request has been received.
	 * 
	 * After the processing of the request is finished, call `send_response` to send a response.
	 * 
	 * @param id     The id of the request.
	 * @param data    The data of the request.
	 */
	public signal void incoming_request(uint id, owned ByteArray? data);
	
	private uint queue_request(ByteArray? data, owned RequestCallback callback)
	{
		Payload payload;
		lock (last_payload_id)
		{
			lock (outgoing_requests)
			{
				uint id = last_payload_id;
				do
				{
					if (id == MAX_ID)
						id = 1;
					else
						id++;
				}
				while (outgoing_requests.contains(id.to_pointer()));
				last_payload_id = id;
				payload = new Payload(id, REQUEST, data, (owned) callback);
				outgoing_requests[id.to_pointer()] = payload;
			}
		}
		
		payload.timeout_id = Timeout.add(uint.max(100, timeout), () => {request_timed_out(payload.id); return false;});
		outgoing_queue.push(payload);
		return payload.id;
	}
	
	/**
	 * Return response for given message id
	 * 
	 * @param id    Message id
	 * @return response data
	 * @throw local or remote errors arisen from the request
	 */
	private ByteArray? get_response(uint id) throws GLib.Error
	{
		bool found;
		Payload? payload;
		lock (outgoing_requests)
		{
			payload = outgoing_requests.take(id.to_pointer(), out found);
		}
		if (!found)
			throw new GLib.IOError.NOT_FOUND("Response with id %u has not been found.", id);
		if (payload.error != null)
			throw payload.error;
		return payload.data;
	}
	
	private bool check_not_closed()
	{
		if (closed)
			return false;
		if (input.is_closed() || output.is_closed())
		{
			try
			{
				close();
			}
			catch (GLib.IOError e)
			{
				debug("Failed to close channel: %s", e.message);
			}
			return false;
		}
		return true;
	}
	
	private void check_not_closed_or_error() throws GLib.IOError
	{
		if (!check_not_closed())
			throw new GLib.IOError.CLOSED("The channel has already been closed");
	}
		
	private void* writer_thread_func()
	{
		while (check_not_closed())
		{
			if (log_comunication)
				debug("Channel(%u) Writer: Waiting for payload", this.id);
			Payload? payload = outgoing_queue.pop();
			if (payload == null)
				break;
			
			if (log_comunication)
				debug("Channel(%u) %s(%u): Send",
					this.id, payload.direction == REQUEST ? "Request": "Response", payload.id);
			
			GLib.Error? error = null;
			try
			{
				write_data_sync(payload.direction, payload.id, payload.data);
			}
			catch (Diorite.IOError e)
			{
				warning("Channel(%u) %s(%u): Failed to send. %s",
					this.id, payload.direction == REQUEST ? "Request": "Response", payload.id, e.message);
				error = e;
			}
			
			if (payload.direction == REQUEST)
			{
				if (error != null)
					process_response(payload, null, error);
			}
		}
		return null;
	}
	
	/**
	 * Loop receiving incoming requests or responses.
	 */
	private void* reader_thread_func()
	{
		while (check_not_closed())
		{
			try
			{
				if (log_comunication)
					debug("Channel(%u) Reader: Waiting for payload", this.id);
				Payload? payload = null;
				bool direction;
				uint id;
				ByteArray data = null;
				read_data_sync(out direction, out id, out data, 0, null); // throws GLib.Error
				
				if (log_comunication)
					debug("Channel(%u) %s(%u): Received",
						this.id, direction == REQUEST ? "Request": "Response", id);
				
				if (direction == REQUEST)
				{
					
					payload = new Payload(id, direction, data, null);
					process_request(payload);
				}
				else // RESPONSE
				{
					lock (outgoing_requests)
					{
						payload = outgoing_requests[id.to_pointer()];
					}
					if (payload == null)
					{
						warning("Channel(%u) %s(%u): Received, but this response is unexpected.",
							this.id, direction == REQUEST ? "Request": "Response", id);
					}
					else
					{
						process_response(payload, data, null);
					}
				}
			}
			catch (GLib.Error e)
			{
				if (e is GLib.IOError.CLOSED)
				{
					debug("%s", e.message);
				}
				else
				{
					warning("Channel(%u) IOError while receiving data: %s", this.id, e.message);
					try
					{
						close();
					}
					catch (GLib.IOError e)
					{
						warning("Failed to close channel. %s", e.message);
					}
				}
				break;
			}
		}
		return null;
	}
	
	/**
	 * Process response to request and call its callback in the main thread.
	 * 
	 * @param msg      request message
	 * @param label    response label
	 * @param data     response data
	 * @param error    response errot
	 */
	private void process_response(Payload payload, ByteArray? data, GLib.Error? error)
	{
		if (error != null)
		{
			payload.data = null;
			payload.error = error;
		}
		else
		{
			payload.data = data;
			payload.error = null;
		}
		if (payload.timeout_id != 0)
		{
			Source.remove(payload.timeout_id);
			payload.timeout_id = 0;
		}
		Idle.add(payload.idle_callback);
	}
	
	/**
	 * Process incoming request in the main thread.
	 * 
	 * @param payload    Request payload.
	 */
	private void process_request(Payload payload)
	{
		Idle.add(() => {incoming_request(payload.id, (owned) payload.data); return false;});
	}
	
	/**
	 * Read header to extract message direction and id
	 * 
	 * @param buffer       message data buffer
	 * @param offset       offset at which the header starts
	 * @param direction    message direction: `RESPONSE` or `REQUEST`
	 * @param id           message id
	 */
	void read_header(uint8[] buffer, uint offset, out bool direction, out uint id, out uint32 size)
	{
		uint32 header;
		Diorite.uint32_from_bytes(buffer, out header, offset);
		Diorite.uint32_from_bytes(buffer, out size, (uint)(offset + sizeof(uint32)));
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
	void write_header(ref uint8[] buffer, uint offset, bool direction, uint id, uint32 size)
	{
		uint32 header = ((uint32) id) | (direction == RESPONSE ? HEADER_MASK : 0);
		Diorite.uint32_to_bytes(ref buffer, header, offset);
		Diorite.uint32_to_bytes(ref buffer, size, (uint)(offset + sizeof(uint32)));
	}
	
	protected void write_data_sync(bool direction, uint32 id, ByteArray? data) throws Diorite.IOError
	{
		if (data.len > get_max_message_size())
			throw new Diorite.IOError.TOO_MANY_DATA("Only %s bytes can be sent.", get_max_message_size().to_string());
		
		uint8* data_ptr;
		unowned uint8[] data_buf;
		uint32 data_size;
		uint32 bytes_written;
		uint8[] header_buffer = new uint8[2 * sizeof(uint32)];
		write_header(ref header_buffer, 0, direction, id, (uint32) data.len);
		bytes_written = 0;
		data_ptr = header_buffer;
		data_size = header_buffer.length;
		do
		{
			try
			{
				data_buf = (uint8[]) (data_ptr + bytes_written);
				data_buf.length = (int)(data_size - bytes_written);
				bytes_written += (uint) output.write(data_buf);
			}
			catch (GLib.IOError e)
			{
				throw new Diorite.IOError.READ("Failed to write header. %s", e.message);
			}
		}
		while (bytes_written < data_size);
		
		bytes_written = 0;
		data_ptr = data.data;
		data_size = data.len;
		do
		{
			try
			{
				data_buf = (uint8[]) (data_ptr + bytes_written);
				data_buf.length =  (int)(data_size - bytes_written);
				bytes_written += (uint) output.write(data_buf);
			}
			catch (GLib.IOError e)
			{
				throw new Diorite.IOError.READ("Failed to write data. %s", e.message);
			}
		}
		while (bytes_written < data_size);
	}
	
	protected void read_data_sync(out bool direction, out uint32 id, out ByteArray data, uint timeout=0, owned Cancellable? cancellable=null) throws GLib.Error
	{
		data = new ByteArray();
		uint8[MESSAGE_BUFSIZE] real_buffer = new uint8[MESSAGE_BUFSIZE];
		unowned uint8[] buffer;
		var bytes_to_read = (int) 2 * sizeof(uint32);
		size_t bytes_read_total = 0;
		size_t bytes_read;
		while (bytes_read_total < bytes_to_read)
		{
			check_not_closed_or_error();
			try
			{
				buffer = (uint8[]) (((uint8*) real_buffer) + bytes_read_total);
				buffer.length = (int)(bytes_to_read - bytes_read_total);
				bytes_read = input.read(buffer, cancellable);
			}
			catch (GLib.IOError e)
			{
				throw new Diorite.IOError.READ("Failed to read message header. %s", e.message);
			}
			if (bytes_read == 0)
			{
				try
				{
					close();
				}
				catch (GLib.Error e)
				{
					debug("Failed to close the channel. %s", e.message);
				}
			}
			bytes_read_total += bytes_read;
		}
		
		uint32 message_size = 0;
		buffer = real_buffer;
		buffer.length = (int) bytes_to_read;
		read_header(buffer, 0, out direction, out id, out message_size);
		if (message_size == 0)
			throw new Diorite.IOError.READ("Empty message received.");
		
		bytes_read_total = 0;
		while (bytes_read_total < message_size)
		{
			check_not_closed_or_error();
			try
			{
				buffer.length = int.min((int)(message_size - bytes_read_total), MESSAGE_BUFSIZE);
				bytes_read = input.read(buffer, cancellable);
			}
			catch (GLib.IOError e)
			{
				throw new Diorite.IOError.READ("Failed to read from socket. %s", e.message);
			}
			if (bytes_read == 0)
			{
				try
				{
					close();
				}
				catch (GLib.Error e)
				{
					debug("Failed to close the channel. %s", e.message);
				}
			}
			buffer.length = (int) bytes_read;
			data.append(buffer);
			bytes_read_total += bytes_read;
		}
	}
	
	protected void clean_up_after_closed()
	{
		closed = true;
		debug("Channel (%u) has been closed.", id); 
		var error_closed = new GLib.IOError.CLOSED("The channel has just been closed.");
		// N.B. Callbacks will clear the outgoing_requests hash table
		lock (outgoing_requests)
		{
			outgoing_requests.for_each((key, payload) => { process_response(payload, null, error_closed); });
		}
	}
	
	protected void request_timed_out(uint id)
	{
		bool found;
		Payload? payload;
		lock (outgoing_requests)
		{
			payload = outgoing_requests.take(id.to_pointer(), out found);
		}
		if (found)
		{
			payload.timeout_id = 0;
			var msg = "Channel (%u) Request (%u) timed out.".printf(this.id, id);
			process_response(payload, null, new GLib.IOError.TIMED_OUT(msg));
			if (timeout_fatal)
				error(msg);
		}
	}
	
	private void on_closed_changed(GLib.Object o, ParamSpec p)
	{
		if (closed)
		{
			clean_up_after_closed();
			notify["closed"].disconnect(on_closed_changed);
		}
	}
	
	/**
	 * Called when a response to the request is received
	 */
	private delegate void RequestCallback();
	
	private class Payload
	{
		public uint id;
		public bool direction;
		public ByteArray? data = null;
		public GLib.Error? error = null;
		public RequestCallback? callback = null;
		public uint timeout_id = 0;
		
		public Payload(uint id, bool direction, owned ByteArray? data, owned RequestCallback? callback)
		{
			this.id = id;
			this.direction = direction;
			this.data = (owned) data;
			this.callback = (owned) callback;
		}
		
		public bool idle_callback()
		{
			this.callback();
			return false;
		}
	}
	
	/**
	 * Returns maximal message size
	 * 
	 * @return maximal message size
	 */
	public static size_t get_max_message_size()
	{
		return uint32.MAX - 2 * sizeof(uint32);
	}
}

} // namespace Drt

#endif
