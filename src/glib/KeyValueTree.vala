/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Diorite
{

public class KeyValueTree: GLib.Object, KeyValueStorage
{
	public SingleList<PropertyBinding> property_bindings {get; protected set;}
	protected Node<Item?> root;
	protected HashTable<string, unowned Node<Item?>> nodes;
	
	public KeyValueTree()
	{
		property_bindings = new SingleList<PropertyBinding>();
		root = new Node<Item?>(null);
		nodes = new HashTable<string, unowned Node<Item?>>(str_hash, str_equal);
	}
	
	public bool has_key(string key)
	{
		unowned Node<Item?> node = nodes[key];
		if (node == null || node.data == null)
			return false;
		
		return node.data.value_set;
	}
	
	public Variant? get_value(string key)
	{
		unowned Node<Item?> node = nodes[key];
		if (node == null || node.data == null)
			return null;
		
		return node.data.get();
	}
	
	public void unset(string key)
	{
		unowned Node<Item?> node = nodes[key];
		if (node != null && node.data != null && node.data.value_set)
		{ 
			var old_value = node.data.value;
			node.data.unset();
			changed(key, old_value);
		}
	}
	
	public string to_string()
	{
		return print();
	}
	
	public string print(string? bullet=null)
	{
		var printer = new Printer(new StringBuilder("root\n"), bullet);
		printer.print(root);
		return printer.buffer.str;
	}
	
	protected unowned Node<Item?> get_or_create_node(string key)
	{
		unowned Node<Item?> node = nodes[key];
		if (node != null)
			return node;
		
		var index = key.last_index_of_char('.');
		unowned Node<Item?> parent = index > 0 ? get_or_create_node(key.substring(0, index)) : root;
		return create_child_node(parent, key, key.substring(index + 1));
	}
	
	protected unowned Node<Item?> create_child_node(Node<Item?> parent, string full_key, string name)
	{
		var node = new Node<Item?>(new Item(name, null, false, null));
		unowned Node<Item?> unowned_node = node;
		parent.append((owned) node);
		nodes[full_key] = unowned_node;
		return unowned_node;
	}
	
	protected void set_value_unboxed(string key, Variant? value)
	{
		unowned Node<Item?> node = get_or_create_node(key);
		return_if_fail(node.data != null);
		var old_value = node.data.get();
		node.data.set(value);
		
		if (old_value != value && (old_value == null || value == null || !old_value.equal(value)))
			changed(key, old_value);
	}
	
	protected void set_default_value_unboxed(string key, Variant? value)
	{
		unowned Node<Item?> node = get_or_create_node(key);
		return_if_fail(node.data != null);
		var old_value = node.data.get();
		node.data.default_value = value;
		var new_value = node.data.get();
		
		if (old_value != new_value
		&& (old_value == null || new_value == null || !old_value.equal(new_value)))
			changed(key, old_value);
	}
	
	[Compact]
	protected class Item
	{
		public string name = null;
		public Variant? value = null;
		public bool value_set = false;
		public Variant? default_value = null;
		
		public Item(string name, Variant? value, bool value_set, Variant? default_value=null)
		{
			this.name = name;
			this.value = value;
			this.value_set = value_set;
			this.default_value = default_value;
		}
		
		public unowned Variant? get()
		{
			return value_set ? value : default_value;
		}
		
		public void set(Variant? value)
		{
			this.value = value;
			value_set = true;
		}
		
		public void unset()
		{
			value = null;
			value_set = false;
		}
	}
	
	[Compact]
	protected class Printer
	{
		public StringBuilder buffer;
		public string bullet;
		public int space_len;
		
		public Printer(owned StringBuilder buffer, string? bullet)
		{
			this.buffer = (owned) buffer;
			this.bullet = bullet != null ? bullet : "  * ";
			this.space_len = this.bullet.length;
		}
		
		public void print(Node<Item?> root, int depth = -1)
		{
			root.traverse(TraverseType.PRE_ORDER, TraverseFlags.ALL, depth, print_node);
		}
		
		private bool print_node(Node<Item?> node)
		{
			if (node.is_root())
				return false;
			
			unowned Item? item = node.data;
			if (item != null)
			{
				var indent = node.depth() - 2;
				if (indent > 0)
					buffer.append(string.nfill(space_len * indent, ' '));
				buffer.append(bullet);
				var value = item.get();
				buffer.append_printf("%s: %s\n", item.name, value != null ? value.print(false) : "(null)");
			}
			return false;
		}
	}
}

} // namespace Diorite

