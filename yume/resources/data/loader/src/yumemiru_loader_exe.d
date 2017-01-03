import procwin;
import std.string, std.stdio, std.stream, std.file, std.path, std.math, std.c.windows.windows, std.c.stdio, std.c.string, std.utf;

struct REMOTE_DATA {
	uint v;
	//WINBASEAPI HINSTANCE WINAPI LoadLibraryA(LPCSTR);
	extern (Windows) HINSTANCE function(LPCSTR) LoadLibrary;
}

extern(C) int test_function(REMOTE_DATA* data = null) {
	//writefln("aaaaaaa");
	data.v = 5;
	return 0;
} void test_function_end() { return; }

void do_process(Process p) {
	REMOTE_DATA data;
	writefln(p.base_name);
	
	p.prepare_rw();
	auto info = p.execute(cast(ubyte[])(&data)[0..1], cast(void *)&test_function, cast(void *)&test_function_end);

	void read_data() {
		auto s = new SliceStream(info.data, 0);
		s.read(cast(ubyte[])(&data)[0..1]);
	}

	Sleep(10);
	read_data();
	writefln(data.v);
	
	//writefln(w.process);
}



void com.talestra.criminalgirls.main() {
	//writefln((&test_function)[0..1].length);

	/*foreach (p; Process.list) {
		writefln(p.pe.pcPriClassBase);
	}*/
	
	//writefln(Process.ListWindows.length);
	
	//writefln(&test_function);
	//writefln(&test_function_ward);
	
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	
	CreateProcessA(
		r"yumemiru.exe",
		"",
		null,
		null,
		0,
		//0x00000008,
		0x00000000,
		null,
		null,
		&si,
		&pi
	);

	while (true) {
		Sleep(50);
		foreach (w; Window.list) {
			if (w._class == "yumemirukusuri") {
				auto p = w.process;
				//do_process(w.process);
				writefln(p);
				//p.inject("xmllite.dll");
				//p.inject(r"C:\projects\googlecode.com\dutils\procwin\temp.dll");
				//p.inject(r"C:\dev\dmd\samples\d\mydll\mydll.dll");
				p.inject(r"yumemiru_loader.dll");
				return;
			}
		}
	}
}