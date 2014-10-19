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
	private Gtk.HeaderBar header_bar;
	private Diorite.SlideInRevealer? header_bar_revealer = null;
	private Gtk.CheckMenuItem? header_bar_checkbox = null;
	
	public ApplicationWindow(Gtk.Application app, bool collapsible_header_bar)
	{
		top_grid = new Gtk.Grid();
		top_grid.orientation = Gtk.Orientation.VERTICAL;
		top_grid.show();
		add(top_grid);
		
		/* Don't show fallback menubar, because all significant actions should be already provided
		 * by a toolbar. Actually, menu bar model is used only for Unity. */
		show_menubar = false;
		
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
			header_bar_revealer.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
			header_bar_revealer.button.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
			top_grid.attach_next_to(header_bar_revealer, null, Gtk.PositionType.TOP, 1, 1);
			header_bar_revealer.revealer.notify["reveal-child"].connect_after(
				on_header_bar_revealer_expanded_changed);
			header_bar_revealer.add(header_bar);
			header_bar_revealer.show();
		}
		else
		{
			top_grid.attach_next_to(header_bar, null, Gtk.PositionType.TOP, 1, 1);
		}
	}
	
	public Gtk.Button? create_menu_button(Gtk.Application app)
	{
		var gs = Gtk.Settings.get_default();
		Gtk.Menu? menu;
		if (gs.gtk_shell_shows_app_menu && !gs.gtk_shell_shows_menubar || app.app_menu == null)
			menu = null;
		else
			menu = new Gtk.Menu.from_model(app.app_menu);
		
		if (header_bar_revealer != null)
		{
			header_bar_checkbox = new Gtk.CheckMenuItem.with_label("Show toolbar");
			header_bar_checkbox.active = header_bar_revealer.revealer.reveal_child;
			header_bar_checkbox.show();
			header_bar_checkbox.toggled.connect_after(on_header_bar_checkbox_toggled);
			header_bar_revealer.show_all();
			if (menu == null)
			{
				menu = new Gtk.Menu();
				menu.add(header_bar_checkbox);
			}
			else
			{
				menu.add(header_bar_checkbox);
				menu.reorder_child(header_bar_checkbox, 0);
			}
		}
		
		if (menu == null)
			return null;
		
		var image = new Gtk.Image.from_icon_name("emblem-system-symbolic",
			Gtk.IconSize.SMALL_TOOLBAR);
		var menu_button = new Gtk.MenuButton();
		menu_button.image = image;
		menu_button.popup = menu;
		return menu_button;
	}
	
	public void create_toolbar(Gtk.Application app, Diorite.ActionsRegistry actions, string[] items)
	{
		Gtk.Button? button;
		for (var i = 0; i < items.length; i++)
		{
			if (items[i] == " ")
			{
				button = create_menu_button(app);
				if (button != null)
						header_bar.pack_end(button);
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
			if (i == items.length -1)
			{
				button = create_menu_button(app);
				if (button != null)
					header_bar.pack_end(button);
			}
		}
		
		header_bar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		header_bar.show_all();
	}
	
	private void on_header_bar_revealer_expanded_changed(GLib.Object o, ParamSpec p)
	{
		var revelaed = header_bar_revealer.revealer.reveal_child;
		header_bar_revealer.button.visible = !revelaed;
		if (header_bar_checkbox != null)
			header_bar_checkbox.active = revelaed;
	}
	
	private void on_header_bar_checkbox_toggled()
	{
		if (header_bar_revealer.revealer.reveal_child != header_bar_checkbox.active)
			header_bar_revealer.revealer.reveal_child = header_bar_checkbox.active;
	}
	
	private void on_title_changed(GLib.Object o, ParamSpec p)
	{
		/* Beware of infinite loop: Newer GTK versions seem to set header bar title automatically. */
		if (header_bar.title != title)
			header_bar.title = title;
	}
}

} // namespace Diorite
