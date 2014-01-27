// ulong DWORD;
// void* HANDLE HWND;
// uint64 WPARAM UINT_PTR
// ulong LPARAM LONG_PTR

[CCode (cheader_filename="windows.h")]
namespace Win32
{

[SimpleType]
[CCode (cname = "HANDLE", cheader_filename = "windows.h")]
[IntegerType (rank = 6)]
public struct Handle
{
	[CCode (cname = "INVALID_HANDLE_VALUE")]
	public static const Handle INVALID;
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms724211%28v=vs.85%29.aspx
	[CCode (cname = "CloseHandle")]
	public bool close();
	
}

[CCode (cname="HANDLE")]
public struct Process: Handle
{
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686714%28v=vs.85%29.aspx
	[CCode (cname = "TerminateProcess")]
	public bool terminate(uint exit_code);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms683215%28v=vs.85%29.aspx
	[CCode (cname = "GetProcessId")]
	public ulong get_id();
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms682658.aspx
	[CCode (cname = "ExitProcess")]
	public static void exit(uint exit_code);
}

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms644958%28v=vs.85%29.aspx
[CCode (cname = "MSG", destroy_func="DispatchMessage")]
public struct Message
{
	public Window hwnd;
	public uint message;
	public uint64 wParam;
	public ulong lParam;
	public ulong  time;
	public Point  pt;

	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms644936%28v=vs.85%29.aspx
	[CCode (cname = "GetMessage")]
	public static bool @get(out Message msg, void* hWnd, uint wMsgFilterMin, uint wMsgFilterMax);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms644946%28v=vs.85%29.aspx
	[CCode (cname = "PostThreadMessage")]
	public static bool post_thread(ulong idThread, uint Msg, uint64 wParam=0, ulong lParam=0);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms644945%28v=vs.85%29.aspx
	[CCode (cname = "PostQuitMessage")]
	public static void post_quit(int exit_code);
	
	[CCode (cname = "WM_QUIT")]
	public const uint WM_QUIT;
	
	[CCode (cname = "WM_CLOSE")]
	public const uint WM_CLOSE;
	
	[CCode (cname = "WM_DESTROY")]
	public const uint WM_DESTROY;
}

// http://msdn.microsoft.com/en-us/library/windows/desktop/dd162805%28v=vs.85%29.aspx
[CCode (cname = "POINT")]
public struct Point
{
	public long x;
	public long y;
}

[CCode (cname="HANDLE")]
public struct Snapshot: Handle
{
	[CCode (cname = "CreateToolhelp32Snapshot", cheader_filename = "tlhelp32.h")]
	public static Snapshot create(ulong flags, ulong process_id);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686728%28v=vs.85%29.aspx
	[CCode (cname = "Thread32First", cheader_filename = "tlhelp32.h")]
	public bool thread_first(ref ThreadEntry32 entry);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686731%28v=vs.85%29.aspx
	[CCode (cname = "Thread32Next", cheader_filename = "tlhelp32.h")]
	public bool thread_next(ref ThreadEntry32 entry);
}


// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686735%28v=vs.85%29.aspx
[CCode (cname = "THREADENTRY32", cheader_filename = "tlhelp32.h")]
public struct ThreadEntry32
{
  ulong dwSize;
  ulong cntUsage;
  ulong th32ThreadID;
  ulong th32OwnerProcessID;
  long  tpBasePri;
  long  tpDeltaPri;
  ulong dwFlags;
}

[SimpleType]
[CCode (cname = "LPCTSTR", cheader_filename = "windows.h")]
public struct String{}

// http://msdn.microsoft.com/en-us/library/ms679360.aspx
[CCode (cname = "GetLastError", cheader_filename = "windows.h")]
ulong get_last_error();

// http://msdn.microsoft.com/en-us/library/ms679351.aspx
[CCode (cname = "FormatMessage", cheader_filename = "windows.h")]
ulong format_message(ulong flags, void* source, ulong message_id,
ulong language_id, out String buffer, long min_size, va_list? arguments);

string get_last_error_msg()
{
	var num = Win32.get_last_error();
	Win32.String err;
	err = (Win32.String)(&err);
	Win32.format_message(0x00000100 | 0x00001000, null, num, 0, out err, 512,  null);
	return "Error %u: %s".printf((uint) num, (string) err);
}


// http://msdn.microsoft.com/en-us/library/windows/desktop/ms683150%28v=vs.85%29.aspx
[CCode (cname = "FreeConsole", cheader_filename = "windows.h")]
bool free_console();

//http://msdn.microsoft.com/en-us/library/windows/desktop/ms681952%28v=vs.85%29.aspx
[CCode (cname = "AttachConsole", cheader_filename = "windows.h")]
bool attach_console(ulong process_id);

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686016%28v=vs.85%29.aspx
[CCode (cname = "SetConsoleCtrlHandler", cheader_filename = "windows.h")]
bool set_console_ctrl_handler(void* handler, bool add=true);

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms683155%28v=vs.85%29.aspx
[CCode (cname = "GenerateConsoleCtrlEvent", cheader_filename = "windows.h")]
bool generate_console_ctrl_event(ulong event, ulong process_group);

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms683242%28v=vs.85%29.aspx
// TODO: handler routine

[CCode (cname = "CTRL_C_EVENT", cheader_filename = "windows.h")]
public const ulong CTRL_C_EVENT;

[CCode (cname = "CTRL_BREAK_EVENT", cheader_filename = "windows.h")]
public const ulong CTRL_BREAK_EVENT;


// http://msdn.microsoft.com/en-us/library/dwwzkt4c.aspx
[CCode (cname = "raise", cheader_filename = "windows.h")]
public int raise(int sig);

[CCode (cname = "SIGTERM", cheader_filename = "windows.h")]
public const int SIGTERM;

[CCode (cname = "SIGINT", cheader_filename = "windows.h")]
public const int SIGINT;

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms633498%28v=vs.85%29.aspx
[CCode (cname = "EnumWindowsProc", cheader_filename = "windows.h")]
public delegate bool EnumWindowsFunc(Window window);

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms633497%28v=vs.85%29.aspx
[CCode (cname = "EnumWindows", cheader_filename = "windows.h")]
public bool enum_windows(EnumWindowsFunc func);

[CCode (cname="HWND")]
public struct Window: Handle
{
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms633522%28v=vs.85%29.aspx
	[CCode (cname = "GetWindowThreadProcessId", cheader_filename = "windows.h")]
	public bool get_process_id(out ulong process_id);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms644950%28v=vs.85%29.aspx
	[CCode (cname = "SendMessage", cheader_filename = "windows.h")]
	public bool send_message(uint message, uint64 wParam=0, ulong lParam=0);
	
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms632682%28v=vs.85%29.aspx
	[CCode (cname = "DestroyWindow", cheader_filename = "windows.h")]
	public bool destroy();
}

} // namespace Win32
