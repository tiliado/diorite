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

public class RandomTest: Drt.TestCase {
    public void test_random_blob() {
        uint8[] result;
        for (int n_bits = 0; n_bits < 9; n_bits++) {
            Random.blob(n_bits, out result);
            expect_not_null<void*>(result, @"$n_bits bits: result not null");
            expect_int_equal(1, result.length, @"$n_bits bits: result 1 byte");
        }

        for (int n_bits = 9; n_bits < 17; n_bits++) {
            Random.blob(n_bits, out result);
            expect_not_null<void*>(result, @"$n_bits bits: result not null");
            expect_int_equal(2, result.length, @"$n_bits bits: result 2 bytes");
        }

        Random.blob(512, out result);
        expect_not_null<void*>(result, "$512 bits: result not null");
        expect_int_equal(512 / 8, result.length, @"512: result $(512 / 8) bytes");
    }

    public void test_random_hexadecimal() {
        string? result;
        for (int n_bits = 0; n_bits < 9; n_bits++) {
            result = Random.hexadecimal(n_bits);
            expect_not_null<void*>(result, @"$n_bits bits: result not null");
            expect_int_equal(2, result.length, @"$n_bits bits: result 2 bytes");
        }

        for (int n_bits = 9; n_bits < 17; n_bits++) {
            result = Random.hexadecimal(n_bits);
            expect_not_null<void*>(result, @"$n_bits bits: result not null");
            expect_int_equal(4, result.length, @"$n_bits bits: result 4 bytes");
        }

        result = Random.hexadecimal(512);
        expect_not_null<void*>(result, "$512 bits: result not null");
        expect_int_equal(512 / 8 * 2, result.length, @"512: result $(512 / 8 * 2) bytes");
    }
}

} // namespace Drt
