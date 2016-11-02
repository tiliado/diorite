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

namespace Drt
{

public class Lst<G>
{
	private Node<G>? first_node;
	public int length {get; private set;}
	private EqualFunc<G> equal_func;
	
	public Lst(EqualFunc<G>? equal_func=null)
	{
		this.equal_func = equal_func ?? direct_equal;
		first_node = null;
		length = 0;
	}
	
	public void append(G item)
	{
		if (first_node == null)
		{
			first_node = new Node<G>(item);
		}
		else{
			unowned Node<G> node = first_node;
			while (node.next_node != null)
				node = node.next_node;
			
			node.next_node = new Node<G>(item);
		}
		length++;
	}
	
	public void prepend(G item)
	{
		first_node = new Node<G>(item, first_node);
		length++;
	}
	
	public void insert(G item, int position)
	{
		unowned Node<G>? node = first_node;
		unowned Node<G>? prev_node = null;
		int pos = 0;
		while (node != null)
		{
			if (pos++ == position)
			{
				var new_node = new Node<G>(item, node);
				if (node == first_node)
					first_node = new_node;
				else
					prev_node.next_node = new_node;
				length++;
				return;
			}
			prev_node = node;
			node = node.next_node;
		}
		if (length != position)
			critical("No node at index %d.", position);
		append(item);
	}
	
	
	public int index(G item)
	{
		return get_node(item, null, null);
	}
	
	private int get_node(G item, out Node<G>? node, out Node<G>? prev_node)
	{
		unowned Node<G>? cursor = first_node;
		unowned Node<G>? prev_cursor = null;
		var index = 0;
		
		while (cursor != null)
		{
			if (equal_func(cursor.value, item))
			{
				node = cursor;
				prev_node = prev_cursor;
				return index;
			}
			prev_cursor = cursor;
			cursor = cursor.next_node;
			index++;
		}
		node = null;
		prev_node = prev_cursor;
		return -1;
	}
	
	public bool contains(G item)
	{
		return get_node(item, null, null) > -1;
	}
	
	public bool remove(G item)
	{
		Node<G>? node;
		Node<G>? prev_node;
		if (get_node(item, out node, out prev_node) > -1)
		{
			if (prev_node == null)
				first_node = node.next_node;
			else
				prev_node.next_node = node.next_node;
			node.next_node = null;
			node = null;
			length--;
			return true;
		}
		return false;
	}
	
	public bool remove_at(int index)
	{
		unowned Node<G>? node = first_node;
		unowned Node<G>? prev_node = null;
		int pos = 0;
		while (node != null)
		{
			if (pos++ == index)
			{
				if (node == first_node)
					first_node = node.next_node;
				else
					prev_node.next_node = node.next_node;
				length--;
				return true;
			}
			prev_node = node;
			node = node.next_node;
		}
		return false;
	}
	
	public G? get(int index)
	{
		unowned Node<G> node = first_node;
		int pos = 0;
		while (node != null)
		{
			if (pos++ == index)
				return node.value;
			node = node.next_node;
		}
		return null;
	}
	
	public void set(int index, G item)
	{
		unowned Node<G> node = first_node;
		int pos = 0;
		while (node != null)
		{
			if (pos++ == index)
			{
				node.value = item;
				return;
			}
			node = node.next_node;
		}
		if (length != index)
			critical("No node at index %d.", index);
		append(item);
	}
	
	public void reverse()
	{
		if (length <= 1)
			return;
		
		Node<G>[] nodes = new Node<G>[length];
		int i = 0;
		var node = first_node;
		while (node != null)
		{
			nodes[i++] = node;
			node = node.next_node;
		}
		
		for (var j = length - 1; j > 0; j--)
		{
			nodes[j].next_node = nodes[j - 1];
		}
		
		first_node = nodes[length - 1];
		nodes[0].next_node = null;
	}
	
	public Iterator<G> iterator()
	{
		return new Iterator<G>(first_node);
	}
	
	public SList<G> to_slist()
	{
		SList<G> slist = null;
		unowned Node<G> node = first_node;
		while (node != null)
		{
			slist.prepend(node.value);
			node = node.next_node;
		}
		slist.reverse();
		return (owned) slist;
	}
	
	public List<G> to_list()
	{
		List<G> list = null;
		unowned Node<G> node = first_node;
		while (node != null)
		{
			list.prepend(node.value);
			node = node.next_node;
		}
		list.reverse();
		return (owned) list;
	}
	
	public class Iterator<G>
	{
		private Node<G>? next_node;
		
		internal Iterator(Node<G>? first_node)
		{
			next_node = first_node;
		}
		
		public bool next()
		{
			return next_node != null;
		}
		
		public G get()
		{
			var node = next_node;
			assert(node != null);
			next_node = next_node.next_node;
			return node.value;
		}
	}
	
	public void clear()
	{
		first_node = null;
		length = 0;
	}
	
	internal class Node<G>
	{
		public G value;
		public Node<G>? next_node;
		
		public Node(G value, Node<G>? next_node=null)
		{
			this.value = value;
			this.next_node = next_node;
		}
	}
}

} // namespace Diorite
