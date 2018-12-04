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

public class ArraysTest: Drt.TestCase {
    public void test_from_2d_uint8() {
        uint8[,] matrix;
        uint8[] actual_value;
        uint8[] expected;

        matrix = {{}};
        actual_value = Arrays.from_2d_uint8(matrix, 1);
        expect_critical_message("DioriteGlib", "*assertion '*' failed", "out of range");
        expect_true(actual_value == null, "null because out of range");

        actual_value = Arrays.from_2d_uint8(matrix, -1);
        expect_critical_message("DioriteGlib", "*assertion '*' failed", "out of range");
        expect_true(actual_value == null, "null because out of range");

        actual_value = Arrays.from_2d_uint8(matrix, 0);
        expected = {};
        expect_true(Blobs.blob_equal(expected, actual_value), "empty array but not null");

        matrix = {{1}, {2}};
        actual_value = Arrays.from_2d_uint8(matrix, 0);
        expected = {1};
        expect_true(Blobs.blob_equal(expected, actual_value), "empty array but not null");

        matrix = {{1, 2}, {3, 4}};
        actual_value = Arrays.from_2d_uint8(matrix, 0);
        expected = {1, 2};
        expect_true(Blobs.blob_equal(expected, actual_value), "first row");
        actual_value = Arrays.from_2d_uint8(matrix, 1);
        expected = {3, 4};
        expect_true(Blobs.blob_equal(expected, actual_value), "second row");
    }
}

} // namespace Drt
