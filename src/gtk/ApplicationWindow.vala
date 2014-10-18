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
	private Gtk.HeaderBar? header_bar = null;
	private Diorite.SlideInRevealer? toolbar_revealer = null;
	private Gtk.CheckMenuItem? toolbar_checkbox = null;
	
	public ApplicationWindow(Gtk.Application app, bool collapsible_toolbar)
	{
		top_grid = new Gtk.Grid();
		top_grid.orientation = Gtk.Orientation.VERTICAL;
		top_grid.show();
		add(top_grid);
		
		/* Don't show fallback menubar, because all significant actions should be already provided
		 * by a toolbar. Actually, menu bar model is used only for Unity. */
		show_menubar = false;
		
		var gs = Gtk.Settings.get_default();
		if (!gs.gtk_shell_shows_menubar && gs.gtk_shell_shows_app_menu)
		{
			/* Assume we are in GNOME Shell, so it's safe to use HeaderBar */
			header_bar = new Gtk.HeaderBar();
			header_bar.show_close_button = true;
			header_bar.show();
			set_titlebar(header_bar);
		}
		else if(collapsible_toolbar)
		{
			/* Other desktop environments, show collapsible toolbar */
			toolbar_revealer = new Diorite.SlideInRevealer();
			top_grid.attach_next_to(toolbar_revealer, null, Gtk.PositionType.TOP, 1, 1);
			toolbar_revealer.revealer.notify["reveal-child"].connect_after(
				on_toolbar_revealer_expanded_changed);
		}
	}
	
	public void create_toolbar(Gtk.Application app, Diorite.ActionsRegistry actions, string[] items)
	{
		if (header_bar != null)
		{
			Gtk.Button? button;
			for (var i = 0; i < items.length; i++)
			{
				if (items[i] == " ")
				{
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
			}
			header_bar.show_all();
		}
		else
		{
			var toolbar = actions.build_toolbar(items);
			var separator = new Gtk.SeparatorToolItem();
			separator.draw = false;
			separator.set_expand(true);
			toolbar.add(separator);
			var gs = Gtk.Settings.get_default();
			Gtk.Menu menu;
			if (gs.gtk_shell_shows_app_menu && !gs.gtk_shell_shows_menubar || app.app_menu == null)
				menu = new Gtk.Menu();
			else
				menu = new Gtk.Menu.from_model(app.app_menu);
			var image = new Gtk.Image.from_icon_name("emblem-system-symbolic",
				Gtk.IconSize.SMALL_TOOLBAR);
			var menu_button = new Gtk.MenuButton();
			menu_button.relief = Gtk.ReliefStyle.NONE;
			menu_button.image = image;
			menu_button.popup = menu;
			var tool_item = new Gtk.ToolItem();
			tool_item.add(menu_button);
			tool_item.show_all();
			toolbar.add(tool_item);
			toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
			
			if (toolbar_revealer != null)
			{
				toolbar_checkbox = new Gtk.CheckMenuItem.with_label("Show toolbar");
				toolbar_checkbox.active = toolbar_revealer.revealer.reveal_child;
				toolbar_checkbox.show();
				toolbar_checkbox.toggled.connect_after(on_toolbar_checkbox_toggled);
				menu_button.popup.add(toolbar_checkbox);
				menu_button.popup.reorder_child(toolbar_checkbox, 0);
				toolbar_revealer.add(toolbar);
				toolbar_revealer.show_all();
			}
			else
			{
				top_grid.attach_next_to(toolbar, null, Gtk.PositionType.TOP, 1, 1);
				toolbar.show();
			}
		}
	}
	
	private void on_toolbar_revealer_expanded_changed(GLib.Object o, ParamSpec p)
	{
		var revelaed = toolbar_revealer.revealer.reveal_child;
		toolbar_revealer.button.visible = !revelaed;
		if (toolbar_checkbox != null)
			toolbar_checkbox.active = revelaed;
	}
	
	private void on_toolbar_checkbox_toggled()
	{
		if (toolbar_revealer.revealer.reveal_child != toolbar_checkbox.active)
			toolbar_revealer.revealer.reveal_child = toolbar_checkbox.active;
	}
}

} // namespace Diorite
