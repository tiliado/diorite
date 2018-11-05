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
 *
 * Tests are under public domain because they might contain useful sample code.
 */

namespace Drt {

public class EventLoopTest: Drt.TestCase {
    public void test_add_idle() {
        var loop = new MainLoop();
        MainContext? ctx = null;
        Drt.EventLoop.add_idle(() => {
            ctx = MainContext.ref_thread_default();
            loop.quit();
            return false;
        });
        loop.run();
        expect_true(MainContext.@default() == ctx, "Current context is global");

        var thread = new Thread<MainContext>(null, () => {
            var thread_ctx = new MainContext();
            thread_ctx.push_thread_default();
            var ctx2 = MainContext.ref_thread_default();
            var loop2 = new MainLoop(ctx2);
            Drt.EventLoop.add_idle(() => {
                ctx = MainContext.get_thread_default();
                loop2.quit();
                return false;
            });
            loop2.run();
            return thread_ctx;
        });
        expect_true(thread.join() == ctx, "Current context is thread-local");
        expect_true(MainContext.@default() != ctx, "Current context is not global");
    }

    public void test_add_timeout_ms() {
        var loop = new MainLoop();
        MainContext? ctx = null;
        Drt.EventLoop.add_timeout_ms(5, () => {
            ctx = MainContext.ref_thread_default();
            loop.quit();
            return false;
        });
        loop.run();
        expect_true(MainContext.@default() == ctx, "Current context is global");

        var thread = new Thread<MainContext>(null, () => {
            var thread_ctx = new MainContext();
            thread_ctx.push_thread_default();
            var ctx2 = MainContext.ref_thread_default();
            var loop2 = new MainLoop(ctx2);
            Drt.EventLoop.add_timeout_ms(5, () => {
                ctx = MainContext.get_thread_default();
                loop2.quit();
                return false;
            });
            loop2.run();
            return thread_ctx;
        });
        expect_true(thread.join() == ctx, "Current context is thread-local");
        expect_true(MainContext.@default() != ctx, "Current context is not global");
    }

    public void test_resume_later() {
        var loop = new MainLoop();
        MainContext? before = null;
        MainContext? after = null;
        run_resume_later.begin((o, res) => {
            run_resume_later.end(res, out before, out after);
            loop.quit();
        });
        loop.run();
        expect_true(after == before, "Before and after contexts are same.");
        expect_true(MainContext.@default() == before, "Before context is global");
        expect_true(MainContext.@default() == after, "After context is global");

        before = null;
        after = null;
        var thread = new Thread<MainContext>(null, () => {
            var thread_ctx = new MainContext();
            thread_ctx.push_thread_default();
            var loop2 = new MainLoop(thread_ctx);
            run_resume_later.begin((o, res) => {
                run_resume_later.end(res, out before, out after);
                loop2.quit();
            });
            loop2.run();
            return thread_ctx;
        });
        var ctx2 = thread.join();
        expect_true(after == before, "Before and after contexts are same.");
        expect_true(MainContext.@default() != before, "Before context is not global");
        expect_true(MainContext.@default() != after, "After context is not global");
        expect_true(ctx2 == before, "Before context is thread-local.");
        expect_true(ctx2 == after, "After context is thread-local.");

    }

    private async void run_resume_later(out MainContext? before, out MainContext? after) {
        before = MainContext.ref_thread_default();
        yield Drt.EventLoop.resume_later();
        after = MainContext.ref_thread_default();

    }
}

} // namespace Drt
