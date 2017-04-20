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

namespace Diorite
{

public class ApplicationWindow: Gtk.ApplicationWindow
{
	public Gtk.Grid top_grid {get; private set;}
	public InfoBarStack info_bars {get; private set;}
	public Gtk.HeaderBar header_bar {get; private set;}
	private Diorite.SlideInRevealer? header_bar_revealer = null;
	private unowned Application app;
	private Gtk.MenuButton menu_button = null;
	private string[]? menu_button_items = null;
	
	public ApplicationWindow(Application app, bool collapsible_header_bar)
	{
		GLib.Object(application: app);
		this.app = app;
		app.add_window(this);
		app.actions.add_to_map_by_scope(Action.SCOPE_WIN, this);
		app.actions.action_added.connect(on_action_added);
		top_grid = new Gtk.Grid();
		top_grid.orientation = Gtk.Orientation.VERTICAL;
		top_grid.show();
		add(top_grid);
		info_bars = new Diorite.InfoBarStack();
		top_grid.add(info_bars);
		info_bars.show();
		/* Don't show fallback menubar, because all significant actions should be already provided
		 * by a toolbar. Actually, menu bar model is used only for Unity. */
		show_menubar = Environment.get_variable("DIORITE_SHOW_MENUBAR") == "true";
		
		header_bar = new Gtk.HeaderBar();
		header_bar.show();
		
		/* Add some padding in GTK+ < 3.11, looks fine in GTK+ 3.12 */
		if (get_gtk_version() < 31100)
		{
			Gtk.Box? title_box = null;
			header_bar.forall((widget) =>
			{
				if (title_box == null && widget is Gtk.Box && widget.get_parent() == header_bar)
					title_box = (Gtk.Box) widget;
			});
			if (title_box != null)
				title_box.margin_left = title_box.margin_right = 12;
		}
		
		if (app.shell.client_side_decorations)
		{
			header_bar.show_close_button = true;
			set_titlebar(header_bar);
			notify["title"].connect_after(on_title_changed);
		}
		else if(collapsible_header_bar)
		{
			/* Other desktop environments, show collapsible toolbar */
			header_bar_revealer = new Diorite.SlideInRevealer();
			header_bar_revealer.button.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
			top_grid.attach_next_to(header_bar_revealer, null, Gtk.PositionType.TOP, 1, 1);
			header_bar_revealer.revealer.notify["reveal-child"].connect_after(
				on_header_bar_revealer_expanded_changed);
			header_bar_revealer.add(header_bar);
			header_bar_revealer.show();
			header_bar_revealer.button.no_show_all = true;
			header_bar_revealer.revealer.reveal_child = true;
		}
		else
		{
			top_grid.attach_next_to(header_bar, null, Gtk.PositionType.TOP, 1, 1);
		}
		
		menu_button = new Gtk.MenuButton();
		var image = new Gtk.Image.from_icon_name("emblem-system-symbolic",
			Gtk.IconSize.SMALL_TOOLBAR);
		menu_button.image = image;
		menu_button.valign = Gtk.Align.CENTER;
		menu_button.vexpand = false;
		menu_button.no_show_all = true;
		update_menu_button();
		app.shell.app_menu_changed.connect(on_app_menu_changed);
	}
	
	~ApplicationWindow()
	{
		app.shell.app_menu_changed.disconnect(on_app_menu_changed);
	}
	
	public void set_menu_button_items(string[]? items)
	{
		menu_button_items = items;
		update_menu_button();
	}
	
	private void update_menu_button()
	{
		var actions = app.actions;
		var menu = menu_button_items != null ? actions.build_menu(menu_button_items, false, false) : new Menu();
		if (header_bar_revealer != null)
		{
			var toggle_toolbar_action = "toggle-toolbar";
			var toggle_toolbar_item = actions.create_menu_item(toggle_toolbar_action, true, false);
			if (toggle_toolbar_item == null)
				actions.add_action(new ToggleAction("view", "win",
					toggle_toolbar_action, "Show toolbar", null, null, null,
					on_header_bar_checkbox_toggled, header_bar_revealer.revealer.reveal_child));
			toggle_toolbar_item = actions.create_menu_item(toggle_toolbar_action, true, false);
			if (toggle_toolbar_item != null)
				menu.append_item(toggle_toolbar_item);
			else
				warning("Failed to create %s item.", toggle_toolbar_action);
		}
		
		var app_menu = app.shell.app_menu;
		if (app_menu != null && (!app.shell.shows_app_menu || app.shell.shows_menu_bar))
			menu.append_section(null, Actions.copy_menu_model(app_menu));
		menu_button.menu_model = menu;
		menu_button.visible = menu.get_n_items() > 0;
	}
	
	private void on_app_menu_changed(DesktopShell shell)
	{
		update_menu_button();
	}
	
	public void create_toolbar(string[] items)
	{
		var children = header_bar.get_children();
		foreach (var child in children)
			header_bar.remove(child);
		
		for (var i = 0; i < items.length; i++)
		{
			if (items[i] == " ")
			{
				/* GTK+ < 3.11.?? seems to have reversed ordering in HeaderBar.pack_end() */
				if (get_gtk_version() >= 31100)
				{
					header_bar.pack_end(menu_button);
					for (var j = items.length - 1; j > i; j--)
						toolbar_pack_end(items[j]);
				}
				else
				{
					for (var j = i + 1; j < items.length; j++)
						toolbar_pack_end(items[j]);
					header_bar.pack_end(menu_button);
				}
				break;
			}
			
			toolbar_pack_start(items[i]);
			if (i == items.length - 1)
				header_bar.pack_end(menu_button);
		}
		
		header_bar.show_all();
	}
	
	public Gtk.Button? get_toolbar_button(string action_name)
	{
		var action = app.actions.get_action(action_name);
		return_val_if_fail(action != null, false);
		var full_name = action.full_name;
		var children = header_bar.get_children();
		foreach (var child in children)
		{
			var button = child as Gtk.Button;
			if (button != null && button.action_name == full_name)
				return button;
		}
		return null;
	}
	
	private bool toolbar_pack_start(string action)
	{
		return_val_if_fail(header_bar != null, false);
		var button = app.actions.create_action_button(action, true, true);
		if (button != null)
		{
			header_bar.pack_start(button);
			return true;
		}
		return false;
	}
	
	private bool toolbar_pack_end(string action)
	{
		return_val_if_fail(header_bar != null, false);
		var button = app.actions.create_action_button(action, true, true);
		if (button != null)
		{
			header_bar.pack_end(button);
			return true;
		}
		return false;
	}
	
	private void on_header_bar_revealer_expanded_changed(GLib.Object o, ParamSpec p)
	{
		var revelaed = header_bar_revealer.revealer.reveal_child;
		header_bar_revealer.button.visible = !revelaed;
	}
	
	private void on_header_bar_checkbox_toggled()
	{
		header_bar_revealer.revealer.reveal_child = !header_bar_revealer.revealer.reveal_child;
	}
	
	private void on_title_changed(GLib.Object o, ParamSpec p)
	{
		/* Beware of infinite loop: Newer GTK versions seem to set header bar title automatically. */
		if (header_bar.title != title)
			header_bar.title = title;
	}
	
	private void on_action_added(Action action)
	{
		if (action.scope == Action.SCOPE_WIN)
			action.add_to_map(this);
	}
}

} // namespace Diorite
