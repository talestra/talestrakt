import std.string, std.stdio, std.stream, std.file, std.path, std.math, std.c.windows.windows, std.c.stdio, std.c.string, std.utf;

uint lengthz(wchar[] s) { for (int n = 0; n < s.length; n++) if (s[n] == 0) return n; return s.length; }
uint lengthz(char[] s) { for (int n = 0; n < s.length; n++) if (s[n] == 0) return n; return s.length; }

class WindowError : Exception {
	this(uint id) {
		auto data = new wchar[0x400];
		data.length = FormatMessageW(0x00001000, null, id, 0x0, data.ptr, data.length, null);
		super(std.string.format("WindowError(%d) : %s", id, data));
	}
	
	static void emit() {
		throw(new WindowError(GetLastError()));
	}
	
	static void wassert(int r) {
		if (r == 0) emit();
	}
}

static extern (Windows) {
	pragma(lib, "kernel32.lib");
	pragma(lib, "user32.lib");
	pragma(lib, "Psapi.lib");

	alias uint SIZE_T;
	alias char TCHAR;
	alias uint* ULONG_PTR;

	HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
	DWORD  FormatMessageW(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, wchar* lpBuffer, DWORD nSize, void *Arguments);

	DWORD  GetModuleInformation(HANDLE hProcess, HMODULE hModule, MODULEINFO* lpmodinfo, DWORD cb);
	
	BOOL   ReadProcessMemory (HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);
	BOOL   WriteProcessMemory(HANDLE hProcess, LPVOID lpBaseAddress, LPCVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesWritten);

	LRESULT CallWindowProcW(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);	

	struct STARTUPINFO {
	  DWORD    cb = STARTUPINFO.sizeof;
	  LPTSTR   lpReserved;
	  LPTSTR   lpDesktop;
	  LPTSTR   lpTitle;
	  DWORD    dwX;
	  DWORD    dwY;
	  DWORD    dwXSize;
	  DWORD    dwYSize;
	  DWORD    dwXCountChars;
	  DWORD    dwYCountChars;
	  DWORD    dwFillAttribute;
	  DWORD    dwFlags;
	  WORD     wShowWindow;
	  WORD     cbReserved2;
	  LPBYTE   lpReserved2;
	  HANDLE   hStdInput;
	  HANDLE   hStdOutput;
	  HANDLE   hStdError;
	}

	struct PROCESS_INFORMATION {
	  HANDLE   hProcess;
	  HANDLE   hThread;
	  DWORD    dwProcessId;
	  DWORD    dwThreadId;
	}

	BOOL CreateProcessA(LPCTSTR lpApplicationName, LPTSTR lpCommandLine, void* lpProcessAttributes, void* lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCTSTR lpCurrentDirectory, STARTUPINFO* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);
	
	
	// Process List
	enum {
		TH32CS_SNAPHEAPLIST = 0x1,
		TH32CS_SNAPPROCESS = 0x2,
		TH32CS_SNAPTHREAD = 0x4,
		TH32CS_SNAPMODULE = 0x8,
		TH32CS_SNAPALL = (TH32CS_SNAPHEAPLIST | TH32CS_SNAPPROCESS | TH32CS_SNAPTHREAD | TH32CS_SNAPMODULE),
		TH32CS_INHERIT = 0x80000000	,
	}
	HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
	BOOL   Process32First(HANDLE hSnapshot, PROCESSENTRY32 *lppe);
	BOOL   Process32Next(HANDLE hSnapshot, PROCESSENTRY32 *lppe);
	//typedef BOOL(CALLBACK *)(HWND,LPARAM);
	alias BOOL function(HWND,LPARAM) WNDENUMPROC;
	BOOL   EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
	LONG   SetWindowLongW(HWND hWnd, int nIndex, LONG dwNewLong);	
	LONG   GetWindowLongW(HWND hWnd, int nIndex);
	
	UINT   RealGetWindowClassW(HWND hwnd, wchar* pszType, UINT cchType);	
	UINT   GetClassNameW(HWND hwnd, wchar* pszType, UINT cchType);	
	
	DWORD  GetWindowThreadProcessId(HWND hWnd, LPDWORD lpdwProcessId);
	
	int GetWindowTextW(HWND hWnd, wchar* lpString, int nMaxCount);	
	
	HANDLE CreateRemoteThread(HANDLE hProcess, void* lpThreadAttributes, SIZE_T dwStackSize, void* lpStartAddress, LPVOID lpParameter, DWORD dwCreationFlags, LPDWORD lpThreadId);
	
	
	LPVOID VirtualAllocEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect);

	struct PROCESSENTRY32 {
		DWORD       dwSize = PROCESSENTRY32.sizeof;
		DWORD       cntUsage;
		DWORD       th32ProcessID;
		ULONG_PTR   th32DefaultHeapID;
		DWORD       th32ModuleID;
		DWORD       cntThreads;
		DWORD       th32ParentProcessID;
		LONG        pcPriClassBase;
		DWORD       dwFlags;
		TCHAR       _szExeFile[MAX_PATH];
		
		char[] szExeFile() { return _szExeFile[0..lengthz(_szExeFile)]; }
	}

	struct MODULEINFO {
		LPVOID   lpBaseOfDll;
		DWORD    SizeOfImage;
		LPVOID   EntryPoint;
	}

	struct PROCESS_MEMORY_COUNTERS_EX {
		DWORD    cb = PROCESS_MEMORY_COUNTERS_EX.sizeof;
		DWORD    PageFaultCount;
		SIZE_T   PeakWorkingSetSize;
		SIZE_T   WorkingSetSize;
		SIZE_T   QuotaPeakPagedPoolUsage;
		SIZE_T   QuotaPagedPoolUsage;
		SIZE_T   QuotaPeakNonPagedPoolUsage;
		SIZE_T   QuotaNonPagedPoolUsage;
		SIZE_T   PagefileUsage;
		SIZE_T   PeakPagefileUsage;
		SIZE_T   PrivateUsage;
	}

	BOOL   EnumProcesses(DWORD* pProcessIds, DWORD cb, DWORD* pBytesReturned);
	BOOL   EnumProcessModules(HANDLE hProcess, HMODULE* lphModule, DWORD cb, LPDWORD lpcbNeeded);
	DWORD  GetModuleBaseNameW(HANDLE hProcess, HMODULE hModule, wchar* lpBaseName, DWORD nSize);
	BOOL   GetProcessMemoryInfo(HANDLE Process, PROCESS_MEMORY_COUNTERS_EX* ppsmemCounters, DWORD cb);
	HWND   FindWindow(LPCTSTR lpClassName, LPCTSTR lpWindowName);

	enum {
		PROCESS_TERMINATE = 1,
		PROCESS_CREATE_THREAD = 2,
		PROCESS_SET_SESSIONID = 4,
		PROCESS_VM_OPERATION = 8,
		PROCESS_VM_READ = 16,
		PROCESS_VM_WRITE = 32,
		PROCESS_DUP_HANDLE = 64,
		PROCESS_CREATE_PROCESS = 128,
		PROCESS_SET_QUOTA = 256,
		PROCESS_SET_INFORMATION = 512,
		PROCESS_QUERY_INFORMATION = 1024,
		PROCESS_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0xFFF),
	}
}

class Module {
	wchar[] base_name() {
		auto data = new wchar[0x1000];
		int len = GetModuleBaseNameW(proc.handle, mod, data.ptr, data.length);
		//WindowError.wassert(len);
		
		//writefln("%d, %d | len:%d", proc.pid, mod, len);
		data.length = len;
		return data;
	}
	
	HMODULE mod;
	Process proc;
	
	this(Process proc, HMODULE mod) {
		this.proc = proc;
		this.mod = mod;
	}
	
	char[] toString() {
		return std.string.format("Module(%d,%d) : %s", proc.pid, mod, base_name);
	}
	
	MODULEINFO minfo() {
		MODULEINFO r;
		GetModuleInformation(proc.handle, mod, &r, r.sizeof);
		return r;
	}
	
	void* base_addr() {
		return minfo().lpBaseOfDll;
	}
}

class ProcessStream : Stream {
	long _position;
	HANDLE handle;
	
	this(HANDLE handle) {
		this.handle = handle;
		readable = true;
		writeable = true;
		seekable = true;
		isopen = true;
	}

	size_t readBlock(void* buffer, size_t size) {
		uint transferred;
		WindowError.wassert(ReadProcessMemory(handle, cast(void *)_position, buffer, size, &transferred));
		_position += transferred;
		return transferred;
	}
	
	size_t writeBlock(void* buffer, size_t size) {
		uint transferred;
		WindowError.wassert(WriteProcessMemory(handle, cast(void *)_position, buffer, size, &transferred));
		_position += transferred;
		return transferred;
	}
	
	ulong seek(long offset, SeekPos whence) {
		switch (whence) {
			case SeekPos.Set    : _position = offset; break;
			case SeekPos.Current: _position += offset; break;
			case SeekPos.End    : _position = 0xFFFFFFFF; break;
		}
		return _position;
	}
	
	Stream slice(void* pos, long size) {
		return new SliceStream(this, cast(long)pos, cast(long)pos + size);
	}
}

class Window {
	HWND hwnd;
	
	this(HWND hwnd) {
		this.hwnd = hwnd;
	}
	
	wchar[] text() {
		auto text = new wchar[0x1000];
		text.length = GetWindowTextW(hwnd, text.ptr, text.length);
		return text;
	}

	wchar[] _class() {
		auto text = new wchar[0x1000];
		text.length = GetClassNameW(hwnd, text.ptr, text.length);
		return text;
	}
	
	
	LONG opIndex(int idx) { return GetWindowLongW(hwnd, idx); }
	LONG opIndexAssign(int idx, LONG value) { return SetWindowLongW(hwnd, idx, value); }

	Process process() {
		uint pid;
		uint thread_id;
		thread_id = GetWindowThreadProcessId(hwnd, &pid);
		return Process.open(pid);
	}
	
	static Window[] list_simple() {
		Window[] list;
		
		extern (Windows) static BOOL EnumWindowsFunc(HWND hwnd, LPARAM param) {
			auto list = cast(Window[]*)param;
			*list ~= new Window(hwnd);
			return true;
		}
		
		EnumWindows(&EnumWindowsFunc, cast(uint)&list);
	
		return list;
	}	
	
	alias list_simple list;
// CreateToolhelp32Snapshot, Process32First, Process32Next, PROCESSENTRY32
// lpPrevWndProc = SetWindowLong(gHW, GWL_WNDPROC, &WindowProc);
// return CallWindowProc(lpPrevWndProc, hw, uMsg, wParam, lParam);	
}

class Process {
	HANDLE handle;
	ProcessStream stream;
	PROCESSENTRY32 pe;
	uint pid() { return pe.th32ProcessID; }
	bool prepared;
	
	void close() {
		if (stream) delete stream;
		if (handle) CloseHandle(handle);
		handle = cast(HANDLE)0;
	}
	
	void prepare_rw() {
		if (prepared) return;
		prepared = true;
		close();
		handle = OpenProcess(
			PROCESS_QUERY_INFORMATION |
			PROCESS_VM_READ |
			PROCESS_VM_WRITE |
			PROCESS_VM_OPERATION |
			PROCESS_CREATE_THREAD |
		0, false, pid);
		stream = new ProcessStream(handle);
	}
	
	static Process open(uint pid) {
		auto p = new Process;
		p.handle = OpenProcess(PROCESS_QUERY_INFORMATION, false, p.pe.th32ProcessID = pid);
		p.stream = new ProcessStream(p.handle);
		return p;
	}

	static Process open(PROCESSENTRY32 pe) {
		auto p = open(pe.th32ProcessID);
		p.pe = pe;
		return p;
	}
	
	static Process[] list_pe() {
		Process[] list;
		PROCESSENTRY32 pe;
		auto snap = CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
		Process32First(snap, &pe);
		do {
			list ~= open(pe);
		} while (Process32Next(snap, &pe) != 0)
		return list;
	}
	
	alias list_pe list;
	
	static Process[] list_simple() {
		auto list = new uint[0x400];
		uint ret_len;
		
		WindowError.wassert(EnumProcesses(list.ptr, list.length * (*list).sizeof, &ret_len));
		
		list.length = ret_len / (*list).sizeof;
		
		Process[] plist; foreach (pid; list) plist ~= open(pid); return plist;
	}
	
	static Process get_by_base_name(wchar[] base_name) {
		foreach (p; list) if (p.base_name == base_name) return p;
		throw(new Exception(format("Can't find '%s'", base_name)));
	}
	
	bool modules_cached;
	Module[] _modules;
	
	Module[] modules() {
		if (!modules_cached) {
			auto list = new HMODULE[0x800];
			uint ret_len;
			
			try {
				WindowError.wassert(EnumProcessModules(handle, list.ptr, list.length * (*list).sizeof, &ret_len));
				list.length = ret_len - (*list).sizeof;
			} catch {
				list.length = 0;
			}
			
			_modules.length = 0;
			foreach (mod; list) _modules ~= new Module(this, mod);

			modules_cached = true;
		}
		
		return _modules;
	}
	
	Module mmodule() {
		auto m = modules;
		if (!m.length) return null;
		return m[0];
	}
	
	wchar[] base_name() {
		auto cm = mmodule;
		return cm ? cm.base_name : std.utf.toUTF16(toString);
	}
	
	void ReadBlock(ubyte[] data, void* addr) {
		ReadProcessMemory(handle, addr, data.ptr, data.sizeof, null);
	}
	
	PROCESS_MEMORY_COUNTERS_EX memory_info() {
		PROCESS_MEMORY_COUNTERS_EX pmce;
		GetProcessMemoryInfo(handle, &pmce, pmce.sizeof);
		return pmce;
	}
	
	long size() {
		return memory_info.WorkingSetSize;
	}
	
	~this() {
		close();
	}
	
	char[] toString() {
		return std.string.format("Process(%d)", pid);
	}
	
	void* alloc(long size) {
		return VirtualAllocEx(handle, null, size, 0x1000 | 0x2000, 0x40);
	}
	
	void* alloc(ubyte[] data) {
		void* addr = alloc(data.length);
		if (data !is null) {
			auto s = new SliceStream(stream, cast(long)addr, cast(long)addr + data.length);
			s.write(data);
		}
		return addr;
	}
	
	struct EXEC_INFO {
		Stream data;
		Stream code;
	}
	
	EXEC_INFO execute(ubyte[] data, ubyte[] code) {
		prepare_rw();
		
		uint thread;
		void* _data = alloc(data); void* _code = alloc(code);
		CreateRemoteThread(handle, null, 0, _code, _data, 0, &thread);
		writefln("execute(", data, ",", code, ")");

		EXEC_INFO info;
		info.data = stream.slice(_data, data.sizeof);
		info.code = stream.slice(_code, code.sizeof);
		return info;
	}
	
	EXEC_INFO execute(ubyte[] data, void* code_start, void* code_end) {
		return execute(data, (cast(ubyte *)code_start)[0..code_end - code_start]);
	}
	
	HANDLE inject(char[] dll) {
		prepare_rw();
		
		HMODULE hKernel32 = GetModuleHandleA("Kernel32");
		void* dll_name = alloc(cast(ubyte[])(dll ~ "\0"));

		HANDLE thread = CreateRemoteThread(
			handle,
			null,
			0,
			GetProcAddress(hKernel32, "LoadLibraryA"),
			dll_name,
			0,
			null
		);
		
		WindowError.wassert(cast(uint)thread);
		
		return thread;
		//writefln(thread);
		
		//WaitForSingleObject(thread, INFINITE);
	}
}
