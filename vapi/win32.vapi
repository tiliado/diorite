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

[CCode (cname="HANDLE")]
public struct FileHandle: Handle
{
	[CCode (cname = "INVALID_HANDLE_VALUE")]
	public static const Handle INVALID;
	
	[CCode (cname = "CreateFile", cheader_filename = "windows.h")]
	public static FileHandle create(String filename, long access, long share_mode,
	LPSECURITY_ATTRIBUTES? security_attrs, long creation_disposition,
	long flag, FileHandle? template_file=null);
	
	// http://msdn.microsoft.com/en-us/library/aa365467.aspx
	[CCode (cname = "ReadFile", cheader_filename = "windows.h")]
	public bool read(uint8[] buffer, out ulong bytes_read, out LPOVERLAPPED? overlapped=null);
	
	[CCode (cname = "WriteFile", cheader_filename = "windows.h")]
	public bool write(uint8[] buffer, out ulong bytes_written, out LPOVERLAPPED? lpOverlapped=null);
	
	[CCode (cname = "FlushFileBuffers", cheader_filename = "windows.h")]
	public bool flush();
	
	
}

[CCode (cname="HANDLE")]
public struct NamedPipe: FileHandle
{
	[CCode (cname = "INVALID_HANDLE_VALUE")]
	public static const Handle INVALID;
	
	[CCode (cname = "CreateNamedPipe", cheader_filename = "windows.h")]
	public static NamedPipe create(String name, long dwOpenMode, long dwPipeMode,
	long nMaxInstances, long nOutBufferSize, long nInBufferSize, long nDefaultTimeOut,
	LPSECURITY_ATTRIBUTES? lpSecurityAttributes);
	
	[CCode (cname = "CreateFile", cheader_filename = "windows.h")]
	public static FileHandle open(String name, long access, long share_mode,
	LPSECURITY_ATTRIBUTES? security_attrs, long creation_disposition,
	long flag, FileHandle? template_file=null);
	
	[CCode (cname = "ConnectNamedPipe", cheader_filename = "windows.h")]
	public bool connect(out LPOVERLAPPED? overlapped=null);
	
	[CCode (cname = "DisconnectNamedPipe", cheader_filename = "windows.h")]
	public bool disconnect();
	
	// http://msdn.microsoft.com/en-us/library/aa365787%28v=vs.85%29.aspx
	[CCode (cname="SetNamedPipeHandleState", cheader_filename = "windows.h")]
	public bool set_state(ref ulong? mode, ulong? max_collection, ulong? timeout);
	
	// http://msdn.microsoft.com/en-us/library/aa365800%28v=vs.85%29.aspx
	[CCode (cname="WaitNamedPipe", cheader_filename = "windows.h")]
	public static bool wait(String name, ulong timeout);
}

[SimpleType]
[CCode (cname = "LPOVERLAPPED", cheader_filename = "windows.h")]
public struct LPOVERLAPPED{}
	
[SimpleType]
[CCode (cname = "LPSECURITY_ATTRIBUTES", cheader_filename = "windows.h")]
public struct LPSECURITY_ATTRIBUTES{}


[CCode (cname="PIPE_ACCESS_DUPLEX", cheader_filename="windows.h")]
public long PIPE_ACCESS_DUPLEX;

[CCode (cname="PIPE_TYPE_BYTE", cheader_filename="windows.h")]
public long PIPE_TYPE_BYTE;

[CCode (cname="PIPE_TYPE_MESSAGE", cheader_filename="windows.h")]
public long PIPE_TYPE_MESSAGE;

[CCode (cname="PIPE_READMODE_BYTE", cheader_filename="windows.h")]
public long PIPE_READMODE_BYTE;

[CCode (cname="PIPE_READMODE_MESSAGE", cheader_filename="windows.h")]
public long PIPE_READMODE_MESSAGE;

[CCode (cname="PIPE_WAIT", cheader_filename="windows.h")]
public long PIPE_WAIT;

[CCode (cname="PIPE_UNLIMITED_INSTANCES", cheader_filename="windows.h")]
public long PIPE_UNLIMITED_INSTANCES;

[CCode (cname="GENERIC_READ", cheader_filename="windows.h")]
public long GENERIC_READ;

[CCode (cname="GENERIC_WRITE", cheader_filename="windows.h")]
public long GENERIC_WRITE;

[CCode (cname="FILE_WRITE_ATTRIBUTES", cheader_filename="windows.h")]
public long FILE_WRITE_ATTRIBUTES;

[CCode (cname="FILE_SHARE_READ", cheader_filename="windows.h")]
public long FILE_SHARE_READ;

[CCode (cname="FILE_SHARE_WRITE", cheader_filename="windows.h")]
public long  FILE_SHARE_WRITE;

[CCode (cname="OPEN_EXISTING", cheader_filename="windows.h")]
public long OPEN_EXISTING;

[CCode (cname="FILE_ATTRIBUTE_NORMAL", cheader_filename="windows.h")]
public long FILE_ATTRIBUTE_NORMAL;

[CCode (cname="ERROR_MORE_DATA", cheader_filename="windows.h")]
public ulong ERROR_MORE_DATA;

[CCode (cname="ERROR_PIPE_BUSY", cheader_filename="windows.h")]
public ulong ERROR_PIPE_BUSY;

[CCode (cname="ERROR_PIPE_CONNECTED", cheader_filename="windows.h")]
public ulong ERROR_PIPE_CONNECTED;
} // namespace Win32
