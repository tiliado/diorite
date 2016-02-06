/* 
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

[Flags]
public enum Countries
{
	CZECH_REPUBLIC, GREAT_BRITAIN, UNITED_STATES, GERMANY, SLOVAKIA;
}

void main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Countries countries = Countries.CZECH_REPUBLIC;
	message("Countries int: %d", countries);
	message(@"Czech Republic: $(Diorite.Flags.is_set(countries, Countries.CZECH_REPUBLIC))");
	message(@"Germany: $(Diorite.Flags.is_set(countries, Countries.GERMANY))");
	countries |= Countries.GERMANY;
	message(@"Czech Republic: $(Diorite.Flags.is_set(countries, Countries.CZECH_REPUBLIC))");
	message(@"Germany: $(Diorite.Flags.is_set(countries, Countries.GERMANY))");
	countries &= ~Countries.CZECH_REPUBLIC;
	message(@"Czech Republic: $(Diorite.Flags.is_set(countries, Countries.CZECH_REPUBLIC))");
	message(@"Germany: $(Diorite.Flags.is_set(countries, Countries.GERMANY))");
}
