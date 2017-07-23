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

namespace Drt
{

public class VectorClockTest: Drt.TestCase
{
	const string A = "A";
	const string B = "B";
	const string C = "C";
	const string D = "D";
		
	public void test_basic_operations()
	{
		var vclock1 = new VectorClock();
		expect_str_equals("<>", vclock1.to_string(), "vclock1");
		var vclock2 = new VectorClock();
		expect_str_equals("<>", vclock2.to_string(), "vclock2");
		expect_true(vclock1.equals(vclock2), "vclock1 == vclock2");
		var vclock3 = new VectorClock(A, 1);
		expect_str_equals("<A=1>", vclock3.to_string(), "vclock3");
		expect_int_equals(VectorClockComparison.SMALLER, vclock1.compare_with(vclock3), "vclock1 < vclock3");
		expect_int_equals(VectorClockComparison.GREATER, vclock3.compare_with(vclock1), "vclock3 > vclock1");
		
		expect_true(vclock1.precedes(vclock3), "vclock1 < vclock3");
		expect_false(vclock1.descends(vclock3), "vclock1 > vclock3");
		expect_false(vclock1.equals(vclock3), "vclock1 = vclock3");
		expect_false(vclock1.conflicts(vclock3), "vclock1 || vclock3");
		
		vclock1.increment(A);
		expect_str_equals("<A=1>", vclock1.to_string(), "vclock1");
		expect_true(vclock1.equals(vclock3), "vclock1 == vclock3");
		vclock2.increment(B);
		expect_str_equals("<B=1>", vclock2.to_string(), "vclock2");
		expect_int_equals(VectorClockComparison.SIMULTANEOUS, vclock2.compare_with(vclock3), "vclock2 || vclock3");
		expect_int_equals(VectorClockComparison.SIMULTANEOUS, vclock3.compare_with(vclock2), "vclock3 || vclock2");
		expect_false(vclock2.equals(vclock3), "vclock2 = vclock3");
		expect_true(vclock2.conflicts(vclock3), "vclock2 || vclock3");
		
		var vclock1_1 = vclock1.dup().increment(A);
		expect_str_equals("<A=2>", vclock1_1.to_string(), "vclock1_1");
		expect_int_equals(VectorClockComparison.SMALLER, vclock1.compare_with(vclock1_1), "vclock1 < vclock1_1");
		
		var vclock2_1 = vclock2.dup_increment(B);
		expect_str_equals("<B=2>", vclock2_1.to_string(), "vclock2_1");
		expect_int_equals(VectorClockComparison.SMALLER, vclock2.compare_with(vclock2_1), "vclock2 < vclock2_1");
		
		var vclock4 = VectorClock.merge(vclock1_1, vclock2_1, vclock3);
		expect_str_equals("<A=2|B=2>", vclock4.to_string(), "vclock4");
		expect_int_equals(VectorClockComparison.GREATER, vclock4.compare_with(vclock1_1), "vclock4 > vclock1_1");
		expect_int_equals(VectorClockComparison.GREATER, vclock4.compare_with(vclock2_1), "vclock4 > vclock2_1");
		expect_int_equals(VectorClockComparison.GREATER, vclock4.compare_with(vclock3), "vclock4 > vclock3");
		expect_int_equals(VectorClockComparison.SMALLER, vclock1_1.compare_with(vclock4), "vclock1_1 < vclock4");
		expect_int_equals(VectorClockComparison.SMALLER, vclock2_1.compare_with(vclock4), "vclock2_1 < vclock4");
		expect_int_equals(VectorClockComparison.SMALLER, vclock3.compare_with(vclock4), "vclock3 < vclock4");
		
		var vclock4_2 = vclock4.dup().increment(C);
		expect_str_equals("<A=2|B=2|C=1>", vclock4_2.to_string(), "vclock4_2");
		expect_int_equals(VectorClockComparison.GREATER, vclock4_2.compare_with(vclock1_1), "vclock4_2 > vclock1_1");
		expect_int_equals(VectorClockComparison.GREATER, vclock4_2.compare_with(vclock2_1), "vclock4_2 > vclock2_1");
		expect_int_equals(VectorClockComparison.GREATER, vclock4_2.compare_with(vclock3), "vclock4_2 > vclock3");
		expect_int_equals(VectorClockComparison.SMALLER, vclock1_1.compare_with(vclock4_2), "vclock1_1 < vclock4_2");
		expect_int_equals(VectorClockComparison.SMALLER, vclock2_1.compare_with(vclock4_2), "vclock2_1 < vclock4_2");
		expect_int_equals(VectorClockComparison.SMALLER, vclock3.compare_with(vclock4_2), "vclock3 < vclock4_2");
	}
	
	public void test_to_and_from_variant()
	{
		var vclock0 = new VectorClock();
		expect_true(vclock0.equals(VectorClock.from_variant(vclock0.to_variant())), "vclock0");
		var vclock1 = new VectorClock(A, 1, B, 2, C, 5, D, 6);
		expect_str_equals("<A=1|B=2|C=5|D=6>", vclock1.to_string(), "vclock1");
		var variant = vclock1.to_variant();
		var vclock2 = VectorClock.from_variant(variant);
		expect_str_equals("<A=1|B=2|C=5|D=6>", vclock2.to_string(), "vclock2");
		expect_true(vclock1.equals(vclock2), "vclock1 == vclock2");
	}
	
	public void test_to_and_from_bytes()
	{
		var vclock0 = new VectorClock();
		expect_true(vclock0.equals(VectorClock.from_bytes(vclock0.to_bytes())), "vclock0");
		var vclock1 = new VectorClock(A, 1, B, 2, C, 5, D, 6);
		expect_str_equals("<A=1|B=2|C=5|D=6>", vclock1.to_string(), "vclock1");
		var bytes = vclock1.to_bytes();
		var vclock2 = VectorClock.from_bytes(bytes);
		expect_str_equals("<A=1|B=2|C=5|D=6>", vclock2.to_string(), "vclock2");
		expect_true(vclock1.equals(vclock2), "vclock1 == vclock2");
	}
}

} // namespace Nuvola
