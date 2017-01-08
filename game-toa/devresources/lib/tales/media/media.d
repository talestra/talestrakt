module tales.media.media;

public import std.c.windows.windows;
private import std.stdio, std.string, std.stream, std.c.stdlib, std.conv, std.math, std.c.stdio, std.c.string, std.file;

public import tales.media.SDL;
public import tales.media.SDL_image;
public import tales.media.SDL_mixer;
public import tales.media.SDL_ttf;
public import tales.media.OPENGL;
import tales.common;

const LPSTR IDC_ARROW = cast(LPSTR)(32512);
const LPSTR IDC_IBEAM = cast(LPSTR)(32513);
const LPSTR IDC_WAIT = cast(LPSTR)(32514);
const LPSTR IDC_CROSS = cast(LPSTR)(32515);
const LPSTR IDC_UPARROW = cast(LPSTR)(32516);
const LPSTR IDC_SIZENWSE = cast(LPSTR)(32642);
const LPSTR IDC_SIZENESW = cast(LPSTR)(32643);
const LPSTR IDC_SIZEWE = cast(LPSTR)(32644);
const LPSTR IDC_SIZENS = cast(LPSTR)(32645);
const LPSTR IDC_SIZEALL = cast(LPSTR)(32646);
const LPSTR IDC_NO = cast(LPSTR)(32648);
const LPSTR IDC_HAND = cast(LPSTR)(32649);
const LPSTR IDC_APPSTARTING = cast(LPSTR)(32650);
const LPSTR IDC_HELP = cast(LPSTR)(32651);
const LPSTR IDC_ICON = cast(LPSTR)(32641);
const LPSTR IDC_SIZE = cast(LPSTR)(32640);

bool function() mediaexit = &do_exit;

bool do_exit() {
	writefln("do_exit");
	exit(-1);
	return false;
}

version (Windows) {
	import std.c.windows.windows;

	extern (Windows) {
		DWORD   SetClassLongA (HWND hWnd, int nIndex, LONG dwNewLong);
		DWORD   GetClassLongA (HWND hWnd, int nIndex);

		HICON   LoadIconA     (HINSTANCE hInstance, LPCSTR lpIconName);
		DWORD   DestroyIcon  (HICON hIcon);
		HGLOBAL LoadResource  (HMODULE hModule, HRSRC hResInfo);
		HRSRC   FindResourceA (HMODULE hModule, LPCTSTR lpName, LPCTSTR lpType);
		DWORD   SizeofResource(HMODULE hModule, HRSRC hResInfo);
		//HMODULE GetModuleHandleA(LPCSTR lpModuleName);

		int SetWindowLongA(HWND hWnd,int nIndex, int dwNewLong);
		int GetWindowLongA(HWND hWnd,int nIndex);

		const int GCL_HICON = (-14);
		const int GWL_STYLE = (-16);

		alias SetClassLongA SetClassLong;
		alias LoadIconA LoadIcon;
		alias FindResourceA FindResource;
		alias GetModuleHandleA GetModuleHandle;
	}
}

extern (C) {
    char*   getenv  (char *);
    int     putenv  (char *);
}

/*// A hash of strings associated to a resource id.
public ushort[string] __resource_list;

version (Windows) {
	pragma(lib, "kernel32.lib");
	import std.c.windows.windows;

	extern (Windows) {
		HGLOBAL LoadResource  (HMODULE hModule, HRSRC hResInfo);
		HRSRC   FindResourceA (HMODULE hModule, LPCTSTR lpName, LPCTSTR lpType);
		DWORD   SizeofResource(HMODULE hModule, HRSRC hResInfo);
	}

	alias FindResourceA FindResource;
}

static class Resources {
	version (Windows) {
		private static HRSRC getp(char[] name) {
			if ((name in __resource_list) is null) return null;
			return FindResource(null, cast(char *)__resource_list[name], cast(char *)0x0A);
		}
	}

	// Obtain a pointer to the resource
	public static void* get(string name) {
		version(Windows) {
			HRSRC hRsrc; if ((hRsrc = getp(name)) is null) return null;
			return LoadResource(null, hRsrc);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return null;
		}
	}

	// Obtain the size of a resource
	public static int size(string name) {
		version (Windows) {
			HRSRC hRsrc; if ((hRsrc = getp(name)) is null) return 0;
			return SizeofResource(null, hRsrc);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return 0;
		}
	}

	// Return if have the resource requested
	public static bool have(string name) {
		version (Windows) {
			return !((name in __resource_list) is null);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return false;
		}
	}
}*/


class Screen {
	private static SDL_Surface *_screen;
	static int workWidth, workHeight;
	static int screenWidth, screenHeight;
	static int FPS = 60;
	private static char[] _Title;
	static char[] Title() { return _Title; }
	static char[] Title(char[] _Title) { SDL_WM_SetCaption(std.string.toStringz(this._Title = _Title), null); return _Title; }

	static int Width() { return workWidth; }
	static int Height() { return workHeight; }

	static void Clear() { glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); }
	static void SwapBuffers() { SDL_GL_SwapBuffers(); }
	static void Delay(uint ms) { SDL_Delay(ms); }

	version (Windows) private static HICON icon;

	static void Frame() {
		Input.Update();
		Delay(1000 / FPS);
		SwapBuffers();
		Clear();
	}

	static void SetEx(int screenWidth, int screenHeight, int workWidth, int workHeight, int windowed) {
		Icon();
		Mouse.Show(IDC_ARROW);
		SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
		if ((_screen = SDL_SetVideoMode(Screen.screenWidth = screenWidth, Screen.screenHeight = screenHeight, 32, SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_OPENGL | (windowed ? 0 : SDL_FULLSCREEN))) is null) {
			throw(new SDLException("Unable to create SDL_Screen"));
		}
		Screen.workWidth = workWidth; Screen.workHeight = workHeight;
		glEnable(GL_LINE_SMOOTH);
	    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		SDL_GL_SwapBuffers();
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	static void Set(int width, int height, bool windowed = true) {
		SetEx(width, height, width, height, windowed);
	}

	static void Enable2D() {
		glViewport(0, 0, screenWidth, screenHeight);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glMatrixMode(GL_TEXTURE   ); glLoadIdentity();
		glMatrixMode(GL_PROJECTION); glLoadIdentity();
		glOrtho(0, workWidth, workHeight, 0, -1.0, 1.0);
		glTranslatef(0, 1, 0);
		glMatrixMode(GL_MODELVIEW); glLoadIdentity();
		glShadeModel(GL_SMOOTH);
		glEnable(GL_SCISSOR_TEST);
		glDisable(GL_TEXTURE_2D);
	}

	static void Disable2D() {
	}

	static void Icon(LPCSTR picon = cast(LPCSTR)101) {
		version (Windows) {
			HWND hwnd;
			HINSTANCE handle = GetModuleHandle(null);
			icon = LoadIcon(handle, picon);
			SDL_SysWMinfo wminfo; SDL_GetWMInfo(&wminfo);
			hwnd = cast(HANDLE)wminfo.window;
			SetClassLong(hwnd, GCL_HICON, cast(LONG)icon);
			SetWindowLongA(hwnd, GWL_STYLE, GetWindowLongA(hwnd, GWL_STYLE) | WS_THICKFRAME | WS_DLGFRAME);
		}
	}

	static void DrawLine(int x1, int y1, int x2, int y2) {
		//glBindTexture(GL_TEXTURE_2D, 0);
		//glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);

		glBegin(GL_LINES);
			glVertex2i(x1, y1);
			glVertex2i(x2, y2);
		glEnd();
	}

	static void DrawFillBox(int x1, int y1, int x2, int y2) {
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);

		glBegin(GL_QUADS);
			glVertex2i(x1, y1);
			glVertex2i(x2, y1);
			glVertex2i(x2, y2);
			glVertex2i(x1, y2);
		glEnd();
	}
}

class SDLException : Exception {
	this(char[] msg) {
		super(msg);
	}

	override char[] toString() {
		return msg ~ "(" ~ std.string.toString(SDL_GetError()) ~ ")";
	}
}

class Input {
	static void Update() {
		SDL_Event event;

		while (SDL_PollEvent(&event)) {
			switch (event.type) {
				case SDL_QUIT:
					mediaexit();
				break;
				case SDL_MOUSEBUTTONDOWN:
				case SDL_MOUSEBUTTONUP:
				break;
				case SDL_KEYDOWN:
				case SDL_KEYUP:
					Keyboard.keys[event.key.keysym.sym] = (event.type == SDL_KEYDOWN);
				break;
				default:
				break;
			}
		}

		Mouse.b = SDL_GetMouseState(&Mouse.x, &Mouse.y);
	}
}

class Mouse {
	static int x, y, b;

	static void Show(LPSTR cur = IDC_ARROW) {
		SDL_Cursor *cursor = SDL_GetCursor();
		cursor.wm_cursor.curs = cast(void *)LoadCursorA(null, cur);
		SDL_SetCursor(cursor);
	}

	static void Hide() {
		SDL_Cursor *cursor = SDL_GetCursor();
		cursor.wm_cursor.curs = cast(void *)0;
		SDL_SetCursor(cursor);
	}
}

alias Mouse mouse;

class Keyboard {
	static bool keys[SDLK_LAST];

	static void Delay(int delay, int interval) {
		SDL_EnableKeyRepeat(delay, interval);
	}

	static bool opIndex(uint idx) {
		return keys[idx];
	}
}

alias Keyboard key;

class Game {
	static void Init() {
		if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) {
			throw(new SDLException("Unable to initialize SDL"));
		}

		putenv("SDL_VIDEO_WINDOW_POS=center");
		putenv("SDL_VIDEO_CENTERED=1");

		if (TTF_Init() != 0) {
			throw(new SDLException("Unable to initialize SDL_TTF"));
		}

		if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) == -1) {
			throw(new SDLException("Unable to initialize SDL_Mixer"));
		}

		SDL_EnableUNICODE(1);

		Screen.Title = "Title";
	}

	static void Quit(int rv = 0) {
		SDL_Quit();
		exit(rv);
	}
}

private int NextPowerOfTwo(int v) { int c = 1; while ((c <<= 1) < v) { } return c; }

private SDL_Surface* SDL_CreateRGBSurfaceForOpenGL(int w, int h, int *rw, int *rh) {
	SDL_Surface *i;

	*rw = NextPowerOfTwo(w); *rh = NextPowerOfTwo(h);
	if (*rw > *rh) *rh = *rw; else *rw = *rh;

	static if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
		i = SDL_CreateRGBSurface(SDL_SWSURFACE, *rw, *rh, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
	} else {
		i = SDL_CreateRGBSurface(SDL_SWSURFACE, *rw, *rh, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
	}

	return i;
}

struct Point { float x, y; }

class Image {
	//private
	public {
		Image father;
		uint CallList;
		uint GlTex;
		int x, y;
		int w, h;
		int rw, rh;
		int cx, cy;
		Point texp[2];
	}

	this(int w, int h) {
		PrepareNew(w, h, NextPowerOfTwo(w), NextPowerOfTwo(h));

		glGenTextures(1, &GlTex);
		glBindTexture(GL_TEXTURE_2D, GlTex);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	private this() {
		CallList = 0;
		father = null;
	}

	private void PrepareNew(int w, int h, int rw, int rh) {
		CallList = 0;

		father = null;
		cy = cx = y = x = 0;
		this.w = w; this.h = h;
		this.rw = rw;
		this.rh = rh;

		UpdateTexPoints();
	}

	~this() {
		if (!father) glDeleteTextures(1, &GlTex);
	}

	int Width() { return w; }
	int Height() { return h; }

	int CenterX() { return cx; }
	int CenterX(int x) { cx = x; UpdateCallList(); return cx; }

	int CenterY() { return cy; }
	int CenterY(int y) { cy = y; UpdateCallList(); return cy; }

	void CenterXY(int x, int y) {
		cx = x; cy = y;
		UpdateCallList();
	}

	private void UpdateTexPoints() {
		texp[0].x = cast(float)x / cast(float)rw;
		texp[0].y = cast(float)y / cast(float)rh;
		texp[1].x = cast(float)(w + x) / cast(float)rw;
		texp[1].y = cast(float)(h + y) / cast(float)rh;

		UpdateCallList();
	}

	private void UpdateCallList() {
		if (CallList) glDeleteLists(CallList, 1);
		CallList = glGenLists(1);

		glNewList(CallList, GL_COMPILE);
			glBindTexture(GL_TEXTURE_2D, GlTex);
			glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_BLEND);
			glBegin(GL_POLYGON);
				glTexCoord2f(texp[0].x, texp[0].y); glVertex2f(0 - cx, 0 - cy);
				glTexCoord2f(texp[1].x, texp[0].y); glVertex2f(w - cx, 0 - cy);
				glTexCoord2f(texp[1].x, texp[1].y); glVertex2f(w - cx, h - cy);
				glTexCoord2f(texp[0].x, texp[1].y); glVertex2f(0 - cx, h - cy);
			glEnd();
		glEndList();
	}

	static Image FromStream(Stream s) {
		return FromRW(SDL_RWFromStream(s), true);
	}

	static Image FromFile(char[] name) {
		return FromRW(SDL_RWFromFile(std.string.toStringz(name), "rb"), true);
	}

	override static Image FromRW(SDL_RWops *s, bool freesrc = true) {
		SDL_Surface* surface, surfaceogl;
		Image i; int rw, rh;

		if ((surface = IMG_Load_RW(s, freesrc)) is null) throw(new Exception("Can't load image from stream"));
		if ((surfaceogl = SDL_CreateRGBSurfaceForOpenGL(surface.w, surface.h, &rw, &rh)) is null) throw(new Exception("Can't create opengl surface"));

		SDL_SetAlpha(surface, 0, SDL_ALPHA_OPAQUE);
		SDL_BlitSurface(surface, null, surfaceogl, null);

		i = new Image;

		i.PrepareNew(surface.w, surface.h, rw, rh);

		glGenTextures(1, &i.GlTex);
		glBindTexture(GL_TEXTURE_2D, i.GlTex);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, surfaceogl.pixels);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		SDL_FreeSurface(surface);
		SDL_FreeSurface(surfaceogl);

		if (freesrc) SDL_FreeRW(s);

		return i;
	}

	Image Cut(int x, int y, int w, int h) {
		Image i = new Image;

		i.GlTex = GlTex;

		if (x < 0) { w += x; x = 0; }
		if (y < 0) { h += y; y = 0; }
		if (x + w > this.x + this.w) { w = this.x + this.w - x; }
		if (y + h > this.y + this.h) { h = this.y + this.h - y; }
		if (w < 0) w = 0;
		if (h < 0) h = 0;

		i.x = x; i.y = y;
		i.w = w; i.h = h;
		i.rw = this.rw; i.rh = this.rh;
		i.cy = i.cx = 0;

		i.father = father ? father : this;

		i.UpdateTexPoints();

		return i;
	}

	void Draw(int x, int y, float alpha = 1, float size = 1, float angle = 0) {
		alpha = (alpha < 0) ? 0 : ((alpha > 1) ? 1 : alpha);

		x -= cx; y -= cy; y--;

		glColor4f(1.0, 1.0, 1.0, alpha);

		glEnable(GL_TEXTURE_2D);

		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();

			glTranslatef(cast(float)x + cx, cast(float)y + cy, 0.0f);

			glRotatef(angle, 0, 0, 1);
			glScalef(size, size, size);

			//glCallList(CallList);
			///*
			glBindTexture(GL_TEXTURE_2D, GlTex);
			glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_BLEND);
			glBegin(GL_POLYGON);
				glTexCoord2f(texp[0].x, texp[0].y); glVertex2f(0 - cx, 0 - cy);
				glTexCoord2f(texp[1].x, texp[0].y); glVertex2f(w - cx, 0 - cy);
				glTexCoord2f(texp[1].x, texp[1].y); glVertex2f(w - cx, h - cy);
				glTexCoord2f(texp[0].x, texp[1].y); glVertex2f(0 - cx, h - cy);
			glEnd();
			//*/

		glMatrixMode(GL_MODELVIEW);
		glPopMatrix();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}
}

extern(C) int SDL_RWFromStream_seek(SDL_RWops *context, int offset, int whence) {
	Stream s = cast(Stream)context.data1;
	return s.seek(offset, cast(SeekPos)whence);
}

extern(C) int SDL_RWFromStream_read(SDL_RWops *context, void *ptr, int size, int maxnum) {
	Stream s = cast(Stream)context.data1;
	return s.read((cast(ubyte*)ptr)[0..size * maxnum]) / size;
}

extern(C) int SDL_RWFromStream_write(SDL_RWops *context, void *ptr, int size, int num) {
	Stream s = cast(Stream)context.data1;
	s.writeExact(ptr, size * num);
	return num;
}

extern(C) int SDL_RWFromStream_close(SDL_RWops *context) {
	Stream s = cast(Stream)context.data1;
	s.close();
	return 0;
}

SDL_RWops* SDL_RWFromStream(Stream s) {
	SDL_RWops *r = SDL_AllocRW();
	r.seek  = &SDL_RWFromStream_seek;
	r.read  = &SDL_RWFromStream_read;
	r.write = &SDL_RWFromStream_write;
	r.close = &SDL_RWFromStream_close;
	r.data1 = cast(void *)s;
	return r;
}

/*
typedef int (*_seek_func_t)(SDL_RWops *context, int offset, int whence);
typedef int (*_read_func_t)(SDL_RWops *context, void *ptr, int size, int maxnum);
typedef int (*_write_func_t)(SDL_RWops *context, void *ptr, int size, int num);
typedef int (*_close_func_t)(SDL_RWops *context);

struct SDL_RWops {
	_seek_func_t seek;
	_read_func_t read;
	_write_func_t write;
	_close_func_t close;

	Uint32 type;
	union {
	    struct {
			int autoclose;
		 	void *fp;
	    }
	    struct {
			Uint8 *base;
		 	Uint8 *here;
			Uint8 *stop;
	    }
	    struct {
			void *data1;
	    }
	}
}
*/

enum {
	_esc     = SDLK_ESCAPE,

	_f1      = SDLK_F1,
	_f2      = SDLK_F2,
	_f3      = SDLK_F3,
	_f4      = SDLK_F4,
	_f5      = SDLK_F5,
	_f6      = SDLK_F6,
	_f7      = SDLK_F8,
	_f8      = SDLK_F8,
	_f9      = SDLK_F9,
	_f10     = SDLK_F10,
	_f11     = SDLK_F11,
	_f12     = SDLK_F12,

	_up      = SDLK_UP,
	_down    = SDLK_DOWN,
	_left    = SDLK_LEFT,
	_right   = SDLK_RIGHT,

	//_enter   = SDLK_KP_ENTER,
	_space   = SDLK_SPACE,

	_0       = SDLK_0,
	_1       = SDLK_1,
	_2       = SDLK_2,
	_3       = SDLK_3,
	_4       = SDLK_4,
	_5       = SDLK_5,
	_6       = SDLK_6,
	_7       = SDLK_7,
	_8       = SDLK_8,
	_9       = SDLK_9,

	_a       = SDLK_a,
	_b       = SDLK_b,
	_c       = SDLK_c,
	_d       = SDLK_d,
	_e       = SDLK_e,
	_f       = SDLK_f,
	_g       = SDLK_g,
	_h       = SDLK_h,
	_i       = SDLK_i,
	_j       = SDLK_j,
	_k       = SDLK_k,
	_l       = SDLK_l,
	_m       = SDLK_m,
	_n       = SDLK_n,
	_o       = SDLK_o,
	_p       = SDLK_p,
	_q       = SDLK_q,
	_r       = SDLK_r,
	_s       = SDLK_s,
	_t       = SDLK_t,
	_u       = SDLK_u,
	_v       = SDLK_v,
	_w       = SDLK_w,
	_x       = SDLK_x,
	_y       = SDLK_y,
	_z       = SDLK_z,

	_ins     = SDLK_INSERT,
	_home    = SDLK_HOME,
	_end     = SDLK_END,
	_pgup    = SDLK_PAGEUP,
	_pgdn    = SDLK_PAGEDOWN,

	_shift   = SDLK_COMPOSE,
	_lshift  = SDLK_LSHIFT,
	_rshift  = SDLK_RSHIFT,

	_kp0     = SDLK_KP0,
	_kp1     = SDLK_KP1,
	_kp2     = SDLK_KP2,
	_kp3     = SDLK_KP3,
	_kp4     = SDLK_KP4,
	_kp5     = SDLK_KP5,
	_kp6     = SDLK_KP6,
	_kp7     = SDLK_KP7,
	_kp8     = SDLK_KP8,
	_kp9     = SDLK_KP9,
	_kp_period = SDLK_KP_PERIOD,
	_kp_divide = SDLK_KP_DIVIDE,
	_kp_multiply = SDLK_KP_MULTIPLY,
	_kp_minus = SDLK_KP_MINUS,
	_kp_plus = SDLK_KP_PLUS,
	_kp_enter = SDLK_KP_ENTER,
	_kp_equals = SDLK_KP_EQUALS,

	_minus = SDLK_KP_MINUS,
	_plus = SDLK_KP_PLUS,

}
const int LOOP_INFINITE = -1;

class Sample {
	Mix_Chunk *sample;

	this() {
		sample = null;
	}

	static Sample FromFile(char[] filename) {
		Sample sample = new Sample;
		sample.sample = Mix_LoadWAV(std.string.toStringz(filename));
		if (!sample.sample) throw(new Exception("Can't load Audio file: '" ~ filename ~ "'"));
		return sample;
	}

	static Sample FromStream(Stream s) {
		Sample sample = new Sample;
		sample.sample = Mix_LoadWAV_RW(SDL_RWFromStream(s), -1);
		if (!sample.sample) throw(new Exception("Can't load Audio Stream"));
		return sample;
	}

	~this() {
		if (sample !is null) Mix_FreeChunk(sample);
	}

	private real vvolume = 1.0;

	real Volume(real v) {
		Mix_VolumeChunk(this.sample, cast(int)(vvolume = v * 128));
		return vvolume;
	}

	real Volume() {
		return vvolume = ((cast(real)Mix_VolumeChunk(this.sample, -1)) / 128);
	}

	Channel Play(int loops = 0, int ms = 0, int ticks = LOOP_INFINITE) {
		return audio.Play(this, loops, ms, ticks);
	}
}

class Channel {
	int channel;

	this(int channel) {
		this.channel = channel;
		//writefln("Register Channel: %d (%d)", this.channel, cast(int)cast(void *)this);
	}

	int Play(Sample sample, int loops = 0, int fadems = 0, int ticks = LOOP_INFINITE) {
		int channel;

		//writefln("Play on Channel: %d (%d)", this.channel, cast(int)cast(void *)this);

		if (fadems == 0) {
			if (ticks == LOOP_INFINITE) {
				channel = Mix_PlayChannel(this.channel, sample.sample, loops);
			} else {
				channel = Mix_PlayChannelTimed(this.channel, sample.sample, loops, ticks);
			}
		} else {
			if (ticks == LOOP_INFINITE) {
				channel = Mix_FadeInChannel(this.channel, sample.sample, loops, fadems);
			} else {
				channel = Mix_FadeInChannelTimed(this.channel, sample.sample, loops, fadems, ticks);
			}
		}

		if (channel < 0) throw(new Exception("Can't play the sample on channel " ~ std.string.toString(channel)));

		return channel;
	}

	void Pause() {
		Mix_Pause(channel);
	}

	void Resume() {
		Mix_Resume(channel);
	}

	void Stop() {
		Mix_HaltChannel(channel);
	}

	void StopAfter(int ms) {
		Mix_ExpireChannel(channel, ms);
	}

	void FadeOut(int ms) {
		Mix_FadeOutChannel(channel, ms);
	}

	bool Playing() {
		return (Mix_Playing(channel) != 0);
	}

	bool Playing(bit set) {
		set ? Resume() : Pause();
		return set;
	}
}

class Music {
	Mix_Music *music;
	char[] tempfile;

	this() {
		music = null;
	}

	~this() {
		//writefln("Music.~this()");
		if (music !is null) Mix_FreeMusic(music);
		if (tempfile) unlink(tempfile.ptr);
	}

	static Music FromStream(Stream s) {
		return FromFile(WrapperStreamToTempFile(s));
	}

	static Music FromFile(char[] filename) {
		Music music = new Music;

		if (filename.length) {
			music.music = Mix_LoadMUS(std.string.toStringz(filename));
			if (music.music is null) throw(new Exception("Can't Load Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}

		return music;
	}

	void Play(int loops = 0, int fadems = 0, double position = 0.0) {
		if (music is null) return;

		int result;

		if (position == 0.0) {
			if (fadems == 0) {
				result = Mix_PlayMusic(music, loops);
			} else {
				result = Mix_FadeInMusic(music, loops, fadems);
			}
		} else {
			result = Mix_FadeInMusicPos(music, loops, fadems, position);
		}

		Volume = vvolume;

		if (result != 0) {
			throw(new Exception("Can't Play Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}
	}

	void FadeOut(int ms) {
		Mix_FadeOutMusic(ms);
	}

	void Stop() {
		Mix_HaltMusic();
	}

	private static real vvolume = 1.0;

	static real Volume(real v) {
		Mix_VolumeMusic(cast(int)((vvolume = v) * 128));
		return v;
	}

	static real Volume() {
		return cast(real)(Mix_VolumeMusic(-1)) / 128;
	}
}

Audio audio;

class Audio {
	Channel[16] channels;
	Channel     freechannel;
	Channel     allchannels;
	//Music       music;

	static this() {
		if (!(SDL_WasInit(SDL_INIT_EVERYTHING) & SDL_INIT_AUDIO)) {
			if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
				throw new Exception("Unable to initialize SDL: " ~ std.string.toString(SDL_GetError()));
			}
		}
		audio = new Audio;
	}

	static ~this() {
		SDL_QuitSubSystem(SDL_INIT_AUDIO);
	}

	this() {
		if (Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 1024) != 0) {
		//if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) != 0) {
			throw(new Exception("Can't Open Audio Mixer"));
		}

		for (int n = 0; n < 16; n++) channels[n] = new Channel(n);
		allchannels = freechannel = new Channel(-1);
	}

	~this() {
		Mix_CloseAudio();
	}

	Channel Play(Sample sample, int loops = 0, int ms = 0, int ticks = LOOP_INFINITE) {
		int channelNumber = freechannel.Play(sample, loops, ms, ticks);
		return channels[channelNumber];
	}

	void Play(Music music, int loops = LOOP_INFINITE, int fadems = 0, double position = 0.0) {
		if (music is null) return;
		music.Play(loops, fadems, position);
	}
}

class Font {
	int    h;
	int    w[0x100];
	GLuint textures[0x100];
	GLuint ListBase;
	int    spacing;
	Point  gcoords[0x100][2];
	Point  gsize[0x100];
	Point  gtrans[0x100];

	void Spacing(int spacing) {
		this.spacing = spacing;
		UpdateGlyphs();
	}

	int Spacing() {
		return this.spacing;
	}

	~this() {
		glDeleteTextures(0x100, textures.ptr);
		glDeleteLists(ListBase, 0x100);
	}

	static Font FromStream(Stream s, int height, int spacing = 0) {
		return FromFile(WrapperStreamToTempFile(s), height, spacing);
	}

	static Font FromFile(char[] name, int height, int spacing = 0) {
		return FromRW(SDL_RWFromFile(std.string.toStringz(name), "rb"), height, spacing, true);
	}

	override static Font FromRW(SDL_RWops *s, int height, int spacing = 0, bool freesrc = true) {
		Font f = new Font; int n;
		f.spacing = spacing;
		TTF_Font *ttf = TTF_OpenFontRW(s, freesrc, height);
		if (!ttf) throw(new Exception("Can't create font from stream"));
		f.ListBase = glGenLists(0x100);
		f.h = height;
		glGenTextures(0x100, f.textures.ptr);
		for (n = 32; n < 0x100; n++) f.CreateGlyph(ttf, n);
		TTF_CloseFont(ttf);
		return f;
	}

	private void UpdateGlyphs() {
		glDeleteLists(ListBase, 0x100);
		for (int n = 0; n < 0x100; n++) UpdateGlyph(n, false);
	}

	private void UpdateGlyph(int c, bool remove = true) {
		if (remove) glDeleteLists(ListBase + c, 1);
		glNewList(this.ListBase + c, GL_COMPILE);
			glPushMatrix();

			glTranslatef(gtrans[c].x, gtrans[c].y, 0);

			glBindTexture(GL_TEXTURE_2D, this.textures[c]);
			glBegin(GL_POLYGON);
				glTexCoord2f(gcoords[c][0].x, gcoords[c][0].y); glVertex2f(0         , 0         );
				glTexCoord2f(gcoords[c][1].x, gcoords[c][0].y); glVertex2f(gsize[c].x, 0         );
				glTexCoord2f(gcoords[c][1].x, gcoords[c][1].y); glVertex2f(gsize[c].x, gsize[c].y);
				glTexCoord2f(gcoords[c][0].x, gcoords[c][1].y); glVertex2f(0         , gsize[c].y);
			glEnd();

			glPopMatrix();
			glTranslatef(w[c] + spacing, 0, 0);
		glEndList();
	}

	private void CreateGlyph(TTF_Font *font, int c) {
		int minx, maxx, miny, maxy, advance;
		int rw = 1, rh = 1; SDL_Rect dest; SDL_Color color; color.r = color.g = color.b = 0xFF;
		SDL_Surface* temp, glyph;

		if ((glyph = TTF_RenderGlyph_Blended(font, c, color)) is null) throw(new Exception("Can't create Glyph"));

		temp = SDL_CreateRGBSurfaceForOpenGL(glyph.w, glyph.h + 1, &rw, &rh);

		dest.x = 0;
		dest.y = 0;
		dest.w = rw;
		dest.h = rh;
		SDL_SetAlpha(glyph, 0, 0);
		SDL_BlitSurface(glyph, null, temp, &dest);
		glBindTexture(GL_TEXTURE_2D, this.textures[c]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, temp.pixels);
		SDL_FreeSurface(temp); TTF_GlyphMetrics(font, c, &minx, &maxx, &miny, &maxy, &advance);

		//advance += spacing;

		float x = cast(float)glyph.w / cast(float)rw, y = cast(float)glyph.h / cast(float)rh;

		w[c] = advance;
		gsize[c].x = glyph.w;
		gsize[c].y = glyph.h;
		gcoords[c][0].x = 0;
		gcoords[c][0].y = 0;
		gcoords[c][1].x = x;
		gcoords[c][1].y = y;

		gtrans[c].x = minx;
		gtrans[c].y = -maxy + TTF_FontAscent(font) + TTF_FontDescent(font);

		UpdateGlyph(c);

		/*
		glNewList(this.ListBase + c, GL_COMPILE);
			glPushMatrix();

				glTranslatef(minx, -maxy + TTF_FontAscent(font) + TTF_FontDescent(font), 0);

				glBindTexture(GL_TEXTURE_2D, this.textures[c]);
				glBegin(GL_POLYGON);
					glTexCoord2f(0, 1); glVertex2f(0, 0);
					glTexCoord2f(x, 1); glVertex2f(glyph.w, 0);
					glTexCoord2f(x, y + 1); glVertex2f(glyph.w, glyph.h);
					glTexCoord2f(0, y + 1); glVertex2f(0, glyph.h);
				glEnd();

			glPopMatrix();
			glTranslatef(advance, 0, 0);
		glEndList();
		*/

		glBindTexture(GL_TEXTURE_2D, 0);

		SDL_FreeSurface(glyph);

		return 0;
	}

	int Width(char[] text) {
		int r = 0;
		for (int n = 0; n < text.length; n++) r += w[cast(int)text[n]];
		return r + spacing * text.length;
	}

	int Height() {
		return h;
	}

	void DrawSimple(char[] text, int x, int y, float scale = 1.0f) {
		glPushAttrib(GL_LIST_BIT | GL_CURRENT_BIT  | GL_ENABLE_BIT | GL_TRANSFORM_BIT);
			glLoadIdentity();

			glDisable(GL_LIGHTING); glEnable(GL_TEXTURE_2D);
			glDisable(GL_DEPTH_TEST); glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

			glListBase(ListBase);

			glPushMatrix();
				glTranslatef(cast(float)x, cast(float)y, 0.0f);
				glScalef(scale, scale, 1.0f);
				glCallLists(text.length, GL_UNSIGNED_BYTE, text.ptr);
			glPopMatrix();

		glPopAttrib();

		glDisable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void Draw(char[] text, int x, int y, float scale = 1.0f) {
		float cscale = scale;

		for (int n = 0, from = 0, cx = x, cy = y, line = 0; n <= text.length; n++) {
			char[] segment;
			char c;
			if (n != text.length && (c = text[n]) != '\n' && c != 3 && c != 2) continue;

			DrawSimple(segment = text[from..n], cx, cy, cscale);

			from = n + 1;

			if (c == '\n') {
				cy += h * scale;
				cx = x;
				line++;
			} else if (n != text.length) {
				cx += Width(segment) * cscale;

				if (text[from] == '{') {
					char[] param;
					int s = from + 1;
					while (from < text.length && text[++from] != '}') { }
					param = text[s..from];
					switch (c) {
						case 2: // Size: \2{1.5}
							try { cscale = toFloat(param); } catch (Exception e) { }
						break;
						case 3: // Color: \3{FFFFFF}
							float r, g, b, a = 1;
							if (param.length % 3 == 0) {
								int v = param.length / 3;
								float div = (v == 2) ? 255 : 15;
								r = cast(float)getdhvalue(param[0 * v..1 * v]) / div;
								g = cast(float)getdhvalue(param[1 * v..2 * v]) / div;
								b = cast(float)getdhvalue(param[2 * v..3 * v]) / div;
							} else if (param.length % 4 == 0) {
								int v = param.length / 3;
								float div = (v == 2) ? 255 : 15;
								r = cast(float)getdhvalue(param[0 * v..1 * v]) / div;
								g = cast(float)getdhvalue(param[1 * v..2 * v]) / div;
								b = cast(float)getdhvalue(param[2 * v..3 * v]) / div;
								a = cast(float)getdhvalue(param[3 * v..4 * v]) / div;
							}
							glColor4f(r, g, b, a);
						break;
						default:
						break;
					}
				}

				n = from++;
			}
		}
		//writefln();
	}
}

class TimeLine {
	enum Interpolation {
		linear,
		sin,
	}

	TimeLine[] childs;
	TimeLine.Interpolation i;
	real from, to;
	int ams, repeats;

	void AddPeriod(TimeLine.Interpolation i, int ms, real from, real to) {
	}

	void BeginCycle(int count) {
	}

	void EndCycle() {
	}

	real GetAt(int ms) {
		if (ms > ams) ms %= ams;

		if (!childs.length) {
			real r, p;
			p = cast(real)ms / cast(real)this.ams;
			switch (i) {
				case TimeLine.Interpolation.linear: r = p; break;
				case TimeLine.Interpolation.sin:    r = sin(p * PI_4); break;
			}
			return from + (to - from) * r;
		}
		return 0;
	}

	int TotalTime() {
		return ams * repeats;
	}
}

class TimeLineObject {
	TimeLine tl;
	int cms;

	void Time(int ms) {
		int tm = tl.TotalTime();
		cms += ms;
		//if ()
		//if (cms > tm) tm =
	}
}

extern(Windows) {
	DWORD GetTempPathA(
	  DWORD nBufferLength,
	  LPTSTR lpBuffer
	);

	UINT GetTempFileNameA(
		LPCTSTR lpPathName,
		LPCTSTR lpPrefixString,
		UINT uUnique,
		LPTSTR lpTempFileName
	);
}

char[] GetTempPath() {
	char[] temp; temp.length = 0x800;
	temp.length = GetTempPathA(temp.length, temp.ptr);
	return temp;
}

char[][] tempnames;

char[] GetTempName(char[] pre = "talesmediatemp") {
	char[] ret; ret.length = 0x800;
	GetTempFileNameA(
		toStringz(GetTempPath()),
		toStringz(pre),
		0,
		ret.ptr
	);
	ret.length = strlen(ret.ptr);
	tempnames ~= ret;
	return ret;
}

char[] WrapperStreamToTempFile(Stream s) {
	char[] fn = GetTempName();
	File f = new File(fn, FileMode.OutNew);
	f.copyFrom(s);
	f.close();
	return fn;
}

static this() {
	Game.Init();
}

static ~this() {
	std.gc.fullCollect();
	foreach (name; tempnames) {
		writefln(name);
		unlink(toStringz(name));
	}

	Game.Quit();
}
