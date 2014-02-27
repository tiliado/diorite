/*
 * Copyright 2013-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

using Win32;

namespace Diorite
{

int main(string[] args)
{
	if (args.length < 2)
	{
		stderr.printf("Not enough arguments.\n");
		return 1;
	}
	
	var pid = uint64.parse(args[1]);
	if (pid <= 0)
	{
		stderr.printf("Invalid pid '%s'.\n", args[1]);
		return 1;
	}
	
	if (!AttachConsole((ulong) pid))
	{
		if(!FreeConsole())
			stderr.printf("Failed to free console. Not fatal. %s\n", GetLastErrorMsg());
		
		if (!AttachConsole((ulong) pid))
		{
			stderr.printf("Failed to attach to the console of %s. %s\n", args[1], GetLastErrorMsg());
			return 2;
		}
	}
	
	if (!SetConsoleCtrlHandler(null))
	{
		stderr.printf("Failed to unset control handler. %s\n", GetLastErrorMsg());
		return 2;
	}
	

	
	stderr.printf("Last error: %s\n", GetLastErrorMsg());
	if (!GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, (ulong) pid))
	{
		stderr.printf("Failed to send Ctrl-Break event to %s. %s\n", args[1], GetLastErrorMsg());
		
		if (!GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0))
		{
			stderr.printf("Failed to send Ctrl-C event to %s.\n", args[1]);
			return 2;
		}
	}
	
	return 0;
}

} // namespace Diorite
