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

using Drt;

namespace Drtgtk {

public delegate void ActionCallback();
public delegate void ActionCallbackWithParam(Variant parameter);

public abstract class Action: GLib.Object {
    public const string SCOPE_NONE = "none";
    public const string SCOPE_APP = "app";
    public const string SCOPE_WIN = "win";

    protected GLib.SimpleAction action;
    protected ActionCallback? callback;
    protected ActionCallbackWithParam? param_callback;
    public string group {get; construct; default = "main";}
    public string scope {get; construct; default = SCOPE_NONE;}
    public string? label {get; construct; default = null;}
    public string? mnemo_label {get; set; default = null;}
    public string? icon {get; construct; default = null;}
    public string? keybinding {get; set; default = null;}
    public string name {get {return action.name;}}
    public string full_name {owned get {return scope + "." + action.name;}}
    public bool enabled {
        get {return action.enabled;}
        set {action.set_enabled(value);}
    }
    public Variant? state {
        owned get {return action.state;}
        set {action.set_state(value);}
    }

    public virtual signal void activated(Variant? parameter) {
        if (param_callback != null)
        param_callback(parameter);
        else if (callback != null)
        callback();
    }

    public virtual void activate(Variant? parameter) {
        if (enabled)
        action.activate(parameter);
        else
        warning("Cannot activate action '%s', because it is disabled.", name);
    }

    public void add_to_map(ActionMap map) {
        map.add_action(action);
    }

    protected void on_action_activated(Variant? parameter) {
        if (!enabled)
        warning("Cannot activate action '%s', because it is disabled.", name);
        else if (parameter == null && this is ToggleAction)
        activate(!this.state.get_boolean());
        else if (parameter == null || !variant_equal(parameter, this.state))
        activated(parameter);
    }
}

public class SimpleAction : Action {
    public SimpleAction(string group, string scope, string name, string? label, string? mnemo_label, string? icon, string? keybinding, owned ActionCallback? callback) {
        Object(group: group, scope: scope, label: label, icon: icon, keybinding: keybinding, mnemo_label: mnemo_label);
        this.callback = (owned) callback;
        action = new GLib.SimpleAction(name, null);
        action.activate.connect(on_action_activated);
        action.change_state.connect(on_action_activated);
    }
}

public class ToggleAction : Action {
    public ToggleAction(string group, string scope, string name, string? label, string? mnemo_label, string? icon, string? keybinding, owned ActionCallback? callback, Variant state) {
        Object(group: group, scope: scope, label: label, icon: icon, keybinding: keybinding, mnemo_label: mnemo_label);
        this.callback = (owned) callback;
        action = new GLib.SimpleAction.stateful(name, null, state);
        action.activate.connect(on_action_activated);
        action.change_state.connect(on_action_activated);
    }

    public override void activate(Variant? parameter) {
        if (parameter == null)
        base.activate(!this.state.get_boolean());
        else if (parameter != null && state != null && parameter.equal(state))
        debug("Toggle action '%s' not activated because of the same state '%s'.", name, parameter.print(false));
        else
        base.activate(parameter);
    }
}

public class RadioAction: Action {
    private RadioOption[] options;

    public RadioAction(string group, string scope, string name, owned ActionCallbackWithParam? callback, Variant state, RadioOption[] options) {
        Object(group: group, scope: scope, label: null, icon: null, keybinding: null, mnemo_label: null);
        this.param_callback = (owned) callback;
        this.options = options;
        action = new GLib.SimpleAction.stateful(name, state.get_type(), state);
        action.activate.connect(on_action_activated);
        action.change_state.connect(on_action_activated);
    }

    public unowned RadioOption[] get_options() {
        return options;
    }

    public RadioOption get_option(int i) {
        return options[i];
    }
}

public class RadioOption {
    public Variant parameter {get; private set;}
    public string? label {get; private set;}
    public string? mnemo_label {get; private set;}
    public string? icon {get; private set;}
    public string? keybinding {get; private set;}

    public RadioOption(Variant parameter, string? label, string? mnemo_label, string? icon, string? keybinding) {
        this.parameter = parameter;
        this.label = label;
        this.mnemo_label = mnemo_label;
        this.icon = icon;
        this.keybinding = keybinding;
    }
}

} // namespace Drtgtk
