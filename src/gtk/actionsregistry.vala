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

public const string ATTRIBUTE_ITEM_ID = "x-diorite-item-id";

public class ActionsRegistry : GLib.Object
{
	private HashTable<string, SingleList<Action?>> groups;
	private HashTable<string, Action?> actions;
	public Gtk.Application app {get; private set;}
	private Gtk.ApplicationWindow? _window = null;
	public Gtk.ApplicationWindow? window
	{
		get
		{
			return _window;
		}
		set
		{
			_window = value;
			if (_window != null)
				add_to_map_by_scope(Action.SCOPE_WIN, _window);
		}
	}
	
	public ActionsRegistry(Gtk.Application app, Gtk.ApplicationWindow? window = null)
	{
		this.app = app;
		this.window = window;
		groups = new HashTable<string, SingleList<Action?>>(str_hash, str_equal); 
		actions = new HashTable<string, Action?>(str_hash, str_equal); 
	}
	
	public signal void action_added(Action action);
	public signal void action_removed(Action action);
	public signal void action_changed(Action action, ParamSpec p);
	
	public void add_actions(Action[] actions)
	{
		foreach (var action in actions)
			add_action(action);
	}
	
	public void add_action(Action action, bool prepend=false)
	{
		var group_name = action.group;
		var group = groups.get(group_name);
		if (group == null)
		{
			group = new SingleList<Action>();
			groups.insert((owned) group_name, group);
		}
		if (prepend)
			group.prepend(action);
		else
			group.append(action);
		actions.set(action.name, action);
		action.activated.connect(on_action_activated);
		var keybinding = action.keybinding;
		if (keybinding != null)
			app.add_accelerator(keybinding, action.scope + "." + action.name, null);
		action.notify.connect_after(on_action_changed);
		switch(action.scope)
		{
		case Action.SCOPE_APP:
			action.add_to_map(app);
			break;
		case Action.SCOPE_WIN:
			if (window != null)
				action.add_to_map(window);
			break;
		}
		action_added(action);
	}
	
	public void remove_action(Action action)
	{
		var group_name = action.group;
		var group = groups.get(group_name);
		if (group != null)
			group.remove(action);
		
		if (actions.remove(action.name))
		{
			action.activated.disconnect(on_action_activated);
			action.notify.disconnect(on_action_changed);
			action_removed(action);
		}
	}
	
	public bool activate_action(string name, Variant? param=null)
	{
		var action = get_action(name);
		if (action == null)
			return false;
		action.activate(param);
		return true;
	}
	
	public Action? get_action(string name)
	{
		return actions.get(name);
	}
	
	public SList<Action?> get_group(string group_name)
	{
		var group = groups.get(group_name);
		if (group == null)
			return new SList<Action?>();
		return group.to_slist();
	}
	
	public List<unowned string> list_groups()
	{
		return groups.get_keys();
	}
	
	public List<weak Action?> list_actions()
	{
		return actions.get_values();
	}
	
	public Menu build_menu(string[] actions, bool use_mnemonic=true, bool use_icons=true)
	{
		var menu = new Menu();
		foreach (var full_name in actions)
		{
			string? detailed_name = null;
			Action? action = null;
			RadioOption? option = null;
			if (!find_and_parse_action(full_name, out detailed_name, out action, out option))
			{
				warning("Action '%s' not found in registry.", full_name);
				continue;
			}
			
			string? label;
			string? icon;
			if (option != null)
			{
				label = (use_mnemonic && option.mnemo_label != null && option.mnemo_label != "")
					? option.mnemo_label : option.label;
				icon = option.icon;
			}
			else
			{
				label = (use_mnemonic && action.mnemo_label != null && action.mnemo_label != "")
					? action.mnemo_label : action.label;
				icon = action.icon;
			}
			var item = new MenuItem(label, action.scope + "." + detailed_name);
			item.set_attribute_value(ATTRIBUTE_ITEM_ID, full_name);
			if (use_icons)
			{
				if (icon != null)
					item.set_icon(new ThemedIcon(icon));
			}
			menu.append_item(item);
		}
		return menu;
	}
	
	public bool find_and_parse_action(string full_name, out string? detailed_name, out Action? action, out RadioOption? option)
	{
		detailed_name = null;
		action = null;
		option = null;
		int option_index = -1;
		string name = ActionsRegistry.parse_full_name(full_name, out option_index);
		action = this.actions.get(name);
		if (action == null)
			return false;
			
		if (option_index >= 0)
		{
			var radio = action as RadioAction;
			if (radio == null)
				return false;
			
			option = radio.get_option(option_index);
			detailed_name = GLib.Action.print_detailed_name(name, option.parameter);
		}
		else
		{
			detailed_name = name;
		}
		return true;
	}
	
	public Gtk.Button? create_action_button(string full_name, bool use_image, bool symbolic_images)
	{
		Diorite.Action action;
		Diorite.RadioOption option;
		string detailed_name;
		if (find_and_parse_action(full_name, out detailed_name, out action, out option))
		{
			string action_name;
			Variant target_value;
			try
			{
				GLib.Action.parse_detailed_name(action.scope + "." + detailed_name, out action_name, out target_value);
			}
			catch (GLib.Error e)
			{
				critical("Failed to parse '%s': %s", action.scope + "." + detailed_name, e.message);
				return null;
			}
			if (action is Diorite.SimpleAction)
			{
				var button = use_image && action.icon != null
				? new Gtk.Button.from_icon_name(
					symbolic_images ? action.icon + "-symbolic" : action.icon,
					Gtk.IconSize.SMALL_TOOLBAR)
				: new Gtk.Button.with_label(action.label);
				button.action_name = action_name;
				button.action_target = target_value;
				button.valign = Gtk.Align.CENTER;
				button.vexpand = false;
				return button;
			}
			else if (action is Diorite.ToggleAction)
			{
				var button = new Gtk.CheckButton.with_label(action.label);
				button.action_name = action_name;
				button.action_target = target_value;
				button.valign = Gtk.Align.CENTER;
				button.vexpand = false;
				return button;
			}
			else if (action is Diorite.RadioAction)
			{
				warning("Diorite.ActionsRegistry.create_action_button doesn't support radio actions.");
				return null;
			}
		}
		return null;
	}
	
	public Gtk.Toolbar build_toolbar(string[] actions, Gtk.Toolbar? toolbar=null)
	{
		var t = toolbar ?? new Gtk.Toolbar();
		foreach (var full_name in actions)
		{
			if (full_name == "|")
			{
				var item = new Gtk.SeparatorToolItem();
				item.draw = true;
				item.set_expand(false);
				t.add(item);
			}
			else if (full_name == " ")
			{
				var item = new Gtk.SeparatorToolItem();
				item.draw = false;
				item.set_expand(true);
				t.add(item);
			}
			else
			{
				string? detailed_name = null;
				Action? action = null;
				RadioOption? option = null;
				if (!find_and_parse_action(full_name, out detailed_name, out action, out option))
				{
					warning("Action '%s' not found in registry.", full_name);
					continue;
				}
				
				string? label;
				string? icon;
				if (option != null)
				{
					label = option.label;
					icon = option.icon;
				}
				else
				{
					label = action.label;
					icon = action.icon;
				}
				
				var button = new Gtk.ToolButton(null, label);
				button.set_action_name(action.scope + "." + detailed_name);
				if (icon != null)
					button.set_icon_name(icon);
				t.add(button);
			}
		}
		return t;
	}
	
	public void add_to_map_by_scope(string scope, ActionMap map)
	{
		foreach (var action in actions.get_values())
			if (action.scope == scope)
				action.add_to_map(map);
	}
	
	public void add_to_map_by_name(string[] names, ActionMap map)
	{
		foreach (var name in names)
		{
			var action = actions.get(name);
			if (action != null)
				action.add_to_map(map);
		}
	}
	
	private void on_action_activated(Action action, Variant? parameter)
	{
		var a = action as Action;
		assert(a != null);
		debug("Action activated: %s/%s.%s(%s)", a.group, a.scope, a.name, parameter == null ? "null" : parameter.print(false));
	}
	
	private void on_action_changed(GLib.Object o, ParamSpec p)
	{
		var action = o as Action;
		if (action == null)
		{
			critical("Passed object has to be Diorite.Action.");
			return;
		}
		
		if (p.name == "keybinding")
		{
			var full_name = action.scope + "." + action.name;
			var accel_name = "<GAction>/" + full_name;
			var keybinding = action.keybinding;
			var found = Gtk.AccelMap.lookup_entry(accel_name, null);
			if (!found && keybinding != null)
			{
				app.add_accelerator(keybinding, full_name, null);
			}
			else if (found)
			{
				uint key = 0;
				Gdk.ModifierType mods = 0;
				if (keybinding != null)
				{
					Gtk.accelerator_parse(keybinding, out key, out mods);
					if (key == 0)
						warning("Failed to parse accelerator: '%s'\n", keybinding);
					else
						Gtk.AccelMap.change_entry(accel_name, key, mods, true);
				}
				else
				{
					Gtk.AccelMap.change_entry(accel_name, key, mods, true);
				}
			}
		}
		action_changed(action, p);
	}
	
	public static string parse_full_name(string full_name, out int option)
	{
		var i = full_name.index_of("::");
		if (i == -1)
		{
			option = -1;
			return full_name;
		}
		
		option = int.parse(full_name.substring(i + 2));
		return full_name.substring(0, i);
	}
}

} // namespace Diorite
