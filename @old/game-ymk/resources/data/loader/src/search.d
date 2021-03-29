import procwin;
import std.string, std.stdio, std.stream, std.file, std.path, std.math, std.c.windows.windows, std.c.stdio, std.c.string, std.utf;

extern (Windows) {
	HANDLE GetStdHandle(DWORD nStdHandle);
	struct COORD {
		SHORT   X;
		SHORT   Y;
	}
	struct SMALL_RECT {
		SHORT   Left;
		SHORT   Top;
		SHORT   Right;
		SHORT   Bottom;
	}
	struct CONSOLE_SCREEN_BUFFER_INFO {
		COORD        dwSize;
		COORD        dwCursorPosition;
		WORD         wAttributes;
		SMALL_RECT   srWindow;
		COORD        dwMaximumWindowSize;
	}
	BOOL SetConsoleCursorPosition(HANDLE hConsoleOutput, COORD dwCursorPosition);
	BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo);
	BOOL FillConsoleOutputCharacterA(HANDLE hConsoleOutput, TCHAR cCharacter, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfCharsWritten);
}

void cls() {
	DWORD cCharsWritten;
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	GetConsoleScreenBufferInfo(GetStdHandle(-11), &csbi);
	FillConsoleOutputCharacterA(GetStdHandle(-11), ' ', csbi.dwSize.X * csbi.dwSize.Y, COORD(0, 0), &cCharsWritten);
}

// 47C130
void do_process(Process p) {
	ulong off = 0x47C130;
	bool first = true;
	int len = 0x1190;
	//int len = 0x2000;
	bool[uint] used;
	auto buf = new ubyte[len];
	auto buf_back = new ubyte[len];
	auto s = p.stream;
	p.prepare_rw();
	
	cls();
	
	while (true) {
		s.position = off;
		s.read(buf);
		//writefln(buf);
		if (!first) {
			
			for (int n = 0; n < len; n++) {
				if (buf[n] != buf_back[n]) used[off + n] = true;
			}

			SetConsoleCursorPosition(GetStdHandle(-11), COORD(0, 0));
			
			foreach (cu; used.keys.sort) {
				writef("%08X", cu);
				int n = cu - off;
				if (buf[n] != buf_back[n]) {
					writef(" : %02X -> %02X", buf_back[n], buf[n]);
				}
				writefln();
			}
			
			// 0047C148,0047C149,0047CE78,0047CE80,0047CE84,0047CE90,0047CE94,0047CE98,0047CE9C
		}
		
		buf_back[0..len] = buf[0..len];
		
		first = false;

		Sleep(100);
	}
}

void com.talestra.criminalgirls.main() {
	foreach (w; Window.list) {
		if (w._class == "yumemirukusuri") {
			do_process(w.process);
		}
	}
}