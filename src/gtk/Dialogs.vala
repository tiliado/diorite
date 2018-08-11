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

using Drt;

namespace Drtgtk
{
/**
 * Simple Error dialog with OK button.
 */
public class ErrorDialog : Gtk.MessageDialog
{
	
	/**
	 * Constructs new error dialog.
	 * 
	 * @param title Title of the error message (not title of the dialog)
	 * @param message Text of the error message
	 * @param use_markup true if message uses Pango markup
	 */
	public ErrorDialog(string title, string message, bool use_markup=false)
	{
		Object(
			title: "",
			modal: true,
			message_type: Gtk.MessageType.ERROR,
			buttons: Gtk.ButtonsType.OK,
			secondary_use_markup: use_markup
		);
		this.text = title;
		this.secondary_text = message;
	}
	
	public override void response(int id)
	{
		this.destroy();
	}
}

/**
 * Simple confirmation dialog with YES and NO buttons.
 */
public class ConfirmDialog : Gtk.MessageDialog
{
	
	/**
	 * Constructs new error dialog.
	 * 
	 * @param title Title of the error message (not title of the dialog)
	 * @param message Text of the error message
	 * @param use_markup true if message uses Pango markup
	 */
	public ConfirmDialog(string title, string message, bool use_markup=false)
	{
		Object(
			title: "",
			modal: true,
			message_type: Gtk.MessageType.QUESTION,
			buttons: Gtk.ButtonsType.YES_NO,
			secondary_use_markup: use_markup
		);
		this.text = title;
		this.secondary_text = message;
	}
	
	public override void response(int id)
	{
		this.destroy();
	}
}

/**
 * Simple Information dialog with OK button.
 */
public class InfoDialog : Gtk.MessageDialog
{
	
	/**
	 * Constructs new error dialog.
	 * 
	 * @param title Title of the error message (not title of the dialog)
	 * @param message Text of the error message
	 * @param use_markup true if message uses Pango markup
	 */
	public InfoDialog(string title, string message, bool use_markup=false)
	{
		Object(
			title: "",
			modal: true,
			message_type: Gtk.MessageType.INFO,
			buttons: Gtk.ButtonsType.OK,
			secondary_use_markup: use_markup
		);
		this.text = title;
		this.secondary_text = message;
	}
	
	public override void response(int id)
	{
		this.destroy();
	}
}



/**
 * Simple Question dialog with YES/NO buttons and checkbox.
 */
public class QuestionDialog: Gtk.MessageDialog
{
	public bool show_again
	{
		get
		{
			return checkbutton == null || !checkbutton.active;
		}
	}
	
	private Gtk.CheckButton? checkbutton;
	
	/**
	 * Constructs new error dialog.
	 * 
	 * @param title            Title of the warning (not title of the dialog)
	 * @param message          Text of the warning
	 * @param show_checkbox    whether to show a checkbox Do not show this warning again
	 */
	public QuestionDialog(string title, string message, bool show_checkbox=false)
	{
		Object(
			title: "",
			modal: true,
			message_type: Gtk.MessageType.QUESTION,
			buttons: Gtk.ButtonsType.YES_NO
		);
		this.text = title;
		this.secondary_text = message;
		
		if (show_checkbox)
		{
			var action_area = get_action_area() as Gtk.ButtonBox;
			checkbutton = new Gtk.CheckButton.with_label(("Do not ask this question again"));
			action_area.pack_start(checkbutton, true, true, 10);
			action_area.reorder_child(checkbutton, 0);
			checkbutton.has_focus = false;
			checkbutton.can_focus = false;
			checkbutton.show();
		}
		else
		{
			checkbutton = null;
		}
	}
	
	public override void response(int id)
	{
		this.destroy();
	}
}

} // namespace Drtgtk
