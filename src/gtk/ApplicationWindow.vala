/*
 * Copyright 2011-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

public class ApplicationWindow: Gtk.ApplicationWindow {
    public Gtk.Grid top_grid {get; private set;}
    public InfoBarStack info_bars {get; private set;}
    public Gtk.HeaderBar header_bar {get; private set;}
    private SlideInRevealer? header_bar_revealer = null;
    protected unowned Application app;
    private Gtk.MenuButton menu_button = null;
    private string[]? menu_button_items = null;
    private SList<unowned Gtk.Button> toolbar_buttons = null;

    public ApplicationWindow(Application app, bool collapsible_header_bar) {
        GLib.Object(application: app);
        this.app = app;
        app.add_window(this);
        app.actions.add_to_map_by_scope(Action.SCOPE_WIN, this);
        app.actions.action_added.connect(on_action_added);
        top_grid = new Gtk.Grid();
        top_grid.orientation = Gtk.Orientation.VERTICAL;
        top_grid.show();
        add(top_grid);
        info_bars = new InfoBarStack();
        top_grid.add(info_bars);
        info_bars.show();
        /* Don't show fallback menubar, because all significant actions should be already provided
         * by a toolbar. Actually, menu bar model is used only for Unity. */
        show_menubar = Environment.get_variable("DIORITE_SHOW_MENUBAR") == "true";

        header_bar = new Gtk.HeaderBar();
        header_bar.show();

        if (app.shell.client_side_decorations) {
            header_bar.show_close_button = true;
            set_titlebar(header_bar);
            notify["title"].connect_after(on_title_changed);
        } else if (collapsible_header_bar) {
            /* Other desktop environments, show collapsible toolbar */
            header_bar_revealer = new SlideInRevealer();
            header_bar_revealer.button.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
            top_grid.attach_next_to(header_bar_revealer, null, Gtk.PositionType.TOP, 1, 1);
            header_bar_revealer.revealer.notify["reveal-child"].connect_after(
                on_header_bar_revealer_expanded_changed);
            header_bar_revealer.add(header_bar);
            header_bar_revealer.show();
            header_bar_revealer.button.no_show_all = true;
            header_bar_revealer.revealer.reveal_child = true;
        } else {
            top_grid.attach_next_to(header_bar, null, Gtk.PositionType.TOP, 1, 1);
        }

        menu_button = new Gtk.MenuButton();
        var image = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.BUTTON);
        menu_button.image = image;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.vexpand = false;
        menu_button.no_show_all = true;
        update_menu_button();
        app.shell.app_menu_changed.connect(on_app_menu_changed);
    }

    ~ApplicationWindow() {
        app.shell.app_menu_changed.disconnect(on_app_menu_changed);
    }

    public void set_menu_button_items(string[]? items) {
        menu_button_items = items;
        update_menu_button();
    }

    private void update_menu_button() {
        Actions actions = app.actions;
        Menu menu = menu_button_items != null ? actions.build_menu(menu_button_items, false, false) : new Menu();
        if (header_bar_revealer != null) {
            unowned string toggle_toolbar_action = "toggle-toolbar";
            MenuItem? toggle_toolbar_item = actions.create_menu_item(toggle_toolbar_action, true, false);
            if (toggle_toolbar_item == null) {
                actions.add_action(new ToggleAction("view", "win",
                    toggle_toolbar_action, "Show toolbar", null, null, null,
                    on_header_bar_checkbox_toggled, header_bar_revealer.revealer.reveal_child));
            }
            toggle_toolbar_item = actions.create_menu_item(toggle_toolbar_action, true, false);
            if (toggle_toolbar_item != null) {
                menu.append_item(toggle_toolbar_item);
            } else {
                warning("Failed to create %s item.", toggle_toolbar_action);
            }
        }

        MenuModel? app_menu = app.shell.app_menu;
        if (app_menu != null) {
            menu.append_section(null, Actions.copy_menu_model(app_menu));
        }
        menu_button.menu_model = menu;
        menu_button.visible = menu.get_n_items() > 0;
    }

    private void on_app_menu_changed(DesktopShell shell) {
        update_menu_button();
    }

    public void create_toolbar(string[] items) {
        foreach (unowned Gtk.Widget button in toolbar_buttons) {
            header_bar.remove(button);
        }
        toolbar_buttons = null;
        List<unowned Gtk.Widget> extra_widgets = header_bar.get_children();

        if (items.length == 0) {
            header_bar.pack_end(menu_button);
        } else {
            for (var i = 0; i < items.length; i++) {
                if (items[i] == " ") {
                    header_bar.pack_end(menu_button);
                    for (int j = items.length - 1; j > i; j--) {
                        toolbar_pack_end(items[j]);
                    }
                    break;
                }
                toolbar_pack_start(items[i]);
                if (i == items.length - 1) {
                    header_bar.pack_end(menu_button);
                }
            }
        }

        foreach (Gtk.Widget widget in extra_widgets) {
            header_bar.remove(widget);
            header_bar.pack_end(widget);
        }
        header_bar.show_all();
    }

    public Gtk.Button? get_toolbar_button(string action_name) {
        Action? action = app.actions.get_action(action_name);
        return_val_if_fail(action != null, false);
        string full_name = action.full_name;
        List<unowned Gtk.Widget> children = header_bar.get_children();
        foreach (unowned Gtk.Widget child in children) {
            var button = child as Gtk.Button;
            if (button != null && button.action_name == full_name) {
                return button;
            }
        }
        return null;
    }

    private bool toolbar_pack_start(string action) {
        return_val_if_fail(header_bar != null, false);
        Gtk.Button? button = app.actions.create_action_button(action, true, true);
        if (button != null) {
            header_bar.pack_start(button);
            toolbar_buttons.prepend(button);
            return true;
        }
        return false;
    }

    private bool toolbar_pack_end(string action) {
        return_val_if_fail(header_bar != null, false);
        Gtk.Button? button = app.actions.create_action_button(action, true, true);
        if (button != null) {
            header_bar.pack_end(button);
            toolbar_buttons.prepend(button);
            return true;
        }
        return false;
    }

    private void on_header_bar_revealer_expanded_changed(GLib.Object o, ParamSpec p) {
        bool revelaed = header_bar_revealer.revealer.reveal_child;
        header_bar_revealer.button.visible = !revelaed;
    }

    private void on_header_bar_checkbox_toggled() {
        header_bar_revealer.revealer.reveal_child = !header_bar_revealer.revealer.reveal_child;
    }

    private void on_title_changed(GLib.Object o, ParamSpec p) {
        /* Beware of infinite loop: Newer GTK versions seem to set header bar title automatically. */
        if (header_bar.title != title) {
            header_bar.title = title;
        }
    }

    private void on_action_added(Action action) {
        if (action.scope == Action.SCOPE_WIN) {
            action.add_to_map(this);
        }
    }
}

} // namespace Drtgtk
