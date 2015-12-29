/*
 * Copyright 2012-2015 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Example
{

private const string WELCOME_TEXT = """
<h1>Nuvola Player 3.0</h1>

<h2>Be connected</h2>
<ul>
  <li>
    Follow Nuvola Player on <a href="https://www.facebook.com/nuvolaplayer">Facebook</a>,
    <a href="https://plus.google.com/110794636546911932554">Google+</a>
    or <a href="https://twitter.com/NuvolaPlayer">Twitter</a>.
  </li>
  <li>
    Subscribe to the Nuvola Player Newsletter: <a href="http://eepurl.com/bLbm5H">weekly (recommended)</a>
    or <a href="http://eepurl.com/bLbtM1">monthly</a>.
  </li>
</ul>

<h2>Explore all features</h2>
<p>We reccommend you to <a href="https://tiliado.github.io/nuvolaplayer/documentation/3.0/explore.html#explore-unity">explore all features</a> including</p>
<ul>
  <li><a href="https://tiliado.github.io/nuvolaplayer/documentation/3.0/explore.html#explore-unity">Unity integration</a></li>
  <li><a href="https://tiliado.github.io/nuvolaplayer/documentation/3.0/explore.html#explore-gnome">GNOME integration</a></li>
  <li><a href="https://tiliado.github.io/nuvolaplayer/documentation/3.0/explore.html#explore-common">Common features</a></li>
  <li><a href="https://tiliado.github.io/nuvolaplayer/documentation/3.0/explore.html#explore-terminal">Command line controller</a></li>
</ul>

<h2>Get help</h2>
<p>Whenever in trouble, select "Help" menu item.</p>
<ul>
  <li><b>Unity</b>: Gear menu button → Help</li>
  <li><b>GNOME</b>: Application menu button → Help</li>
</ul>

<h2>Become a Patron</h2>
<p>
  Development of Nuvola Player depends on voluntary payments from users.
  <a href="https://tiliado.eu/nuvolaplayer/funding/">Support the project</a> financially and enjoy
  <a href="https://tiliado.eu/accounts/group/3/">the benefits of the Nuvola Patron membership</a>.
</p>
""";

const string TEXT = """
<h1>Heading 1</h1>
<h2>Heading 2</h2>

<p>
    <a href="http://google.com"><b>Lorem ipsum</b> <i>dolor sit amet</i></a>, consetetur sadipscing elitr, sed diam
    nonumyeirmod tempor invidunt ut labore et dolore magna aliquyam erat,
    sed diamvoluptua. <b><i>At vero</i> eos</b> et accusam et justo duo dolores et
    ea rebum. Stet clita kasd gubergren, no sea <a href="http://valadoc.org">takimata sanctus</a> est
    Lorem ipsum dolor sit amet.
</p>

<h2>Heading 2</h2>
<h3>Heading 3</h3>
<p>
    <i><b>Lorem</b> ipsum</i> dolorBR<br/>sit amet,BR<br /> consetetur sadipscing elitr,
    sed diam nonumyeirmod tempor invidunt ut labore et dolore
    magna aliquyam erat, sed diamvoluptua. At vero eos et
    accusam et justo duo dolores et ea reb.
</p>
<p>
    <img src="data://boxes_1234.svg" /><img src="data://boxes_5678.svg" />
</p>
<p>
    <img src="data://boxes_1234.svg" width="200"/> = image scaled to 200px<br/>
    <img src="data://boxes_5678.svg" width="24" /> = image scaled to 24px
</p>
<dl>
    <dt>Name</dt>
    <dd>Jiří Janoušek</dd>
    <dt>Favorite colors</dt>
    <dd><i>Blue</i></dd>
    <dd>White</dd>
    <dt>About</dt>
    <dd>
        <i><b>Lorem</b> ipsum</i> dolor sit amet, consetetur sadipscing elitr,
        sed diam nonumyeirmod tempor invidunt ut labore et dolore
        magna aliquyam erat, sed diamvoluptua. At vero eos et
        accusam et justo duo dolores et ea reb.
    </dd>
</dl>

<ul>
    <li>
        <i><b>Lorem</b> ipsum</i> dolor sit amet, consetetur sadipscing elitr,
        sed diam nonumyeirmod tempor invidunt ut labore et dolore
        magna aliquyam erat, sed diamvoluptua. At vero eos et
        accusam et justo duo dolores et ea reb.
    </li>
    <li>
        <i><b>Lorem</b> ipsum</i> dolor sit amet, consetetur sadipscing elitr,
        sed diam nonumyeirmod tempor invidunt ut labore et dolore
        magna aliquyam erat, sed diamvoluptua. At vero eos et
        accusam et justo duo dolores et ea reb.
    </li>
    <li>
        <i><b>Lorem</b> ipsum</i> dolor sit amet, consetetur sadipscing elitr,
        sed diam nonumyeirmod tempor invidunt ut labore et dolore
        magna aliquyam erat, sed diamvoluptua. At vero eos et
        accusam et justo duo dolores et ea reb.
    </li>
</ul>
""";

int main(string[] args)
{
	
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	var window = new Gtk.Window();
	window.delete_event.connect(() => { quit(); return false;});
	window.show();
	
	
	var buffer = new Diorite.RichTextBuffer();
	buffer.image_locator = image_requested;
	
	try
	{
		
		buffer.load(WELCOME_TEXT);
		buffer.append(TEXT);
		
	}
	catch(MarkupError e)
	{
		assert_not_reached();
	}
	
	var view = new Diorite.RichTextView(buffer);
	var scroll = new Gtk.ScrolledWindow(null, null);
	scroll.set_size_request(400, 400);
	scroll.add(view);
	window.add(scroll);
	window.show_all();
	Gtk.main();
	return 0;
}

private void quit()
{
	Gtk.main_quit();
}	
	
private string image_requested(string uri)
{
	if (uri.has_prefix("data://"))
		return "./RichTextView/" + uri.substring(7);
	else
		return uri;
}

}
