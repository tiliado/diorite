[CCode (cheader_filename="windows.h")]
namespace Win32
{

[SimpleType]
[CCode (cname="HANDLE", has_type_id=false)]
[IntegerType (rank = 6)]
public struct Process
{
	// http://msdn.microsoft.com/en-us/library/windows/desktop/ms686714%28v=vs.85%29.aspx
	[CCode (cname = "TerminateProcess")]
	public bool terminate(uint exit_code);
}

} // namespace Win32
