/*
 * Copyright 2011-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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
	private Gtk.HeaderBar header_bar;
	private Diorite.SlideInRevealer? header_bar_revealer = null;
	private unowned Application app;
	private Gtk.MenuButton menu_button = null;
	
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
		var gs = Gtk.Settings.get_default();
		if (!gs.gtk_shell_shows_menubar && gs.gtk_shell_shows_app_menu)
		{
			/* Assume we are in GNOME Shell, so it's safe to use HeaderBar as window title */
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
	}
	
	public void create_menu_button(string[] items)
	{
		if (menu_button == null)
		{
			menu_button = new Gtk.MenuButton();
			var image = new Gtk.Image.from_icon_name("emblem-system-symbolic",
				Gtk.IconSize.SMALL_TOOLBAR);
			menu_button.image = image;
			menu_button.no_show_all = true;
		}
		
		var actions = app.actions;
		var gs = Gtk.Settings.get_default();
		var menu = actions.build_menu(items, false, false);
		
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
		
		var app_menu = app.app_menu;
		if (app_menu != null && (!gs.gtk_shell_shows_app_menu || gs.gtk_shell_shows_menubar))
		{
			var size = app_menu.get_n_items();
			var section = new Menu();
			for (var i = 0; i < size; i++)
				section.append_item(new MenuItem.from_model(app_menu, i));
			menu.append_section(null, section);
		}
		
		menu_button.menu_model = menu;
		menu_button.visible = menu.get_n_items() > 0;
	}
	
	public void create_toolbar(string[] items)
	{
		Gtk.Button? button;
		var actions = app.actions;
		if (menu_button == null)
			create_menu_button({});
		
		for (var i = 0; i < items.length; i++)
		{
			if (items[i] == " ")
			{
				header_bar.pack_end(menu_button);
				for (var j = items.length - 1; j > i; j--)
				{
					button = actions.create_action_button(items[j], true, true);
					if (button != null)
						header_bar.pack_end(button);
				}
				break;
			}
			
			button = actions.create_action_button(items[i], true, true);
			if (button != null)
				header_bar.pack_start(button);
			
			if (i == items.length - 1)
				header_bar.pack_end(menu_button);
		}
		
		header_bar.show_all();
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
