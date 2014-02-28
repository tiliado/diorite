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

public delegate void ActionCallback();

public class Action: GLib.Object
{
	public static const string SCOPE_NONE = "none";
	public static const string SCOPE_APP = "app";
	public static const string SCOPE_WIN = "win";
	
	private SimpleAction action;
	private ActionCallback? callback;
	public string group {get; construct; default = "main";}
	public string scope {get; construct; default = SCOPE_NONE;}
	public string? label {get; construct; default = null;}
	public string? mnemo_label {get; set; default = null;}
	public string? icon {get; construct; default = null;}
	public string? keybinding {get; set; default = null;}
	public string name {get {return action.name;}}
	public bool enabled {get {return action.enabled;}}
	
	public Action(string group, string scope, string name, string? label, string? mnemo_label, string? icon, string? keybinding, owned ActionCallback? callback)
	{
		Object(group: group, scope: scope, label: label, icon: icon, keybinding: keybinding, mnemo_label: mnemo_label);
		this.callback = (owned) callback;
		action = new SimpleAction(name, null);
		action.activate.connect(on_action_activated);
	}
	
	public virtual signal void activated(Variant? parameter)
	{
		if (callback != null)
			callback();
	}
	
	public void activate(Variant? parameter)
	{
		action.activate(parameter);
	}
	
	public void add_to_map(ActionMap map)
	{
		map.add_action(action);
	}
	
	private void on_action_activated(Variant? parameter)
	{
		activated(parameter);
	}
}

} // namespace Diorite
