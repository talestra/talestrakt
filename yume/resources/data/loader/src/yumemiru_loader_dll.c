//+---------------------------------------------------------------------------
//
//  dll.c - Windows DLL example - dynamically linked part
//

#include <windows.h>
#include <stdio.h>
#include <fcntl.h>
#include <time.h>

#define DLL_EXPORT __declspec(dllexport)

WNDPROC lpPrevWndProc;

#define uint unsigned int

uint *ADDR_SCRIPT_START = 0x0047C144;
uint *ADDR_SCRIPT_CUR   = 0x0047C148;
uint *ADDR_SCRIPT_SIZE  = 0x0047C130;
char *ADDR_SCRIPT       = 0x0047C134;
char *ADDR_TITLE        = 0x0047D2C0;
char *ADDR_TEXT         = 0x0047D6C0;

/*
void process_hook_text_script(unsigned int *stack) {
}

unsigned char new_call_func[] = {
	0x54,             // push esp

	0xB8, 1, 0, 0, 1, // mov eax, VALUE
	0xFF, 0xD0,       // call eax
	
	0x83, 0xC4, 4,    // add esp, 4

	0xB8, 2, 0, 0, 2, // mov eax, VALUE
	0xFF, 0xE0,       // jmp eax
3, 0, 0, 3};

void intercept_func_call(HWND hw, unsigned int call_addr) {
	HANDLE pid, hProc;
	//0x0040BDEA
	unsigned int write_addr = (call_addr + 1);
	unsigned int write_value = (unsigned int)new_call_func - (call_addr + 5);
	unsigned int back_call = (*(unsigned int *)write_addr) + (call_addr + 5);
	
	GetWindowThreadProcessId(hw, &pid);
	hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
	WriteProcessMemory(hProc, write_addr, &write_value, sizeof(write_value), NULL);
	
	{
		unsigned char* ptr = new_call_func;
		for (; *(unsigned int *)ptr != 0x3000003; ptr++) {
			unsigned int *ptr2 = (unsigned int *)ptr;
			if (*ptr2 == 0x1000001) *ptr2 = process_hook_text_script;
			if (*ptr2 == 0x2000002) *ptr2 = back_call;
		}
	}	
}
*/

LRESULT WndProc(HWND hw, UINT uMsg, WPARAM wParam, LPARAM lParam) {
	//printf("WndProc! (%d, %d, %d, %d)\n", hw, uMsg, wParam, lParam);
	char temp[1024];
	int cur = *ADDR_SCRIPT_CUR - *ADDR_SCRIPT_START, len = *ADDR_SCRIPT_SIZE;

	sprintf(temp, "Yume: %s (%-6d/%6d) %3d%%  @  %s", ADDR_SCRIPT, cur, len, (cur * 100) / len, ADDR_TITLE);
	SetConsoleTitle(temp);

	switch (uMsg) {
		case 257:
			if (wParam == 115) {
				char temp[128];
				time_t ctime;
				struct tm *t;
				
				ctime = time(NULL);
				
				t = localtime(&ctime);

				strftime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S", t);

				//printf("'%s' '%s' (%08X)\n", stack[7], stack[8], stack[8]);
				char* addr = (char *)0x0047D6C0;
				//printf("%08X\n", stack[1]);
				
				printf("%s@%s:%s:'%s':'%s':'%s'\n", getenv("USERNAME"), getenv("USERDOMAIN"), temp, ADDR_SCRIPT, ADDR_TITLE, ADDR_TEXT);
				{
					FILE *f = fopen("log.txt", "ab");
					if (f) {
						fprintf(f, "%s@%s:%s:'%s':'%s':'%s'\n", getenv("USERNAME"), getenv("USERDOMAIN"), temp, ADDR_SCRIPT, ADDR_TITLE, ADDR_TEXT);
						fclose(f);
					} else {
						printf("Error al abrir 'log.txt' para escritura.\n");
					}
				}
			}
		break;
	}
	//printf("%d\n", lpPrevWndProc);
	return CallWindowProc(lpPrevWndProc, hw, uMsg, wParam, lParam);		
}

void InitConsole() {
	AllocConsole();

	// redirect unbuffered STDOUT to the console
	*stdout = *_fdopen(_open_osfhandle((long)GetStdHandle(STD_OUTPUT_HANDLE), _O_TEXT), "w");
	setvbuf(stdout, NULL, _IONBF, 0);

	// redirect unbuffered STDIN to the console
	*stdin = *_fdopen(_open_osfhandle((long)GetStdHandle(STD_INPUT_HANDLE), _O_TEXT), "r");
	setvbuf(stdin, NULL, _IONBF, 0);
}

WINAPI BOOL EnumWindowsFunc(HWND hwnd, LPARAM param) {
	char temp[0x400];
	GetClassName(hwnd, temp, sizeof(temp));
	if (strcmp(temp, "yumemirukusuri") == 0) {
		//printf("%d, %d : %s\n", hwnd, param, temp);
		*((HWND *)param) = hwnd;
		return 0;
	}
	return 1;
}


void attached() {
	InitConsole();
	printf("¡Inicializado!\n");
	HWND hwnd = (HWND)0;
	EnumWindows(EnumWindowsFunc, (long)&hwnd);
	printf("hwnd: %d\n", hwnd);
	printf("Pulsa F4 para guardar una frase conflictiva (se guarda en log.txt)\n");
	lpPrevWndProc = (WNDPROC)SetWindowLong(hwnd, GWL_WNDPROC, (long)WndProc);
}

WINAPI BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    switch (ulReason) {
		case DLL_PROCESS_ATTACH: attached(); break;
		case DLL_PROCESS_DETACH: break;
		case DLL_THREAD_ATTACH: case DLL_THREAD_DETACH: return 0;
    }
    //g_hInst=hInstance;
    return 1;
}

