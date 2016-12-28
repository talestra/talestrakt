module cdtool;

import std.stdio, std.string, std.path, std.stream;

extern(C) void* isowrite_open(char *name);
extern(C) void  isowrite_close(void*);
extern(C) void* isoread_open(char *name);
extern(C) void  isoread_close(void*);
extern(C) void* isowrite_isoread_copy_basics(void *iso, void *cdutil);
extern(C) void* isowrite_create_dir(void *iso, void *dir, char *name);
extern(C) void  isowrite_create_file(void *iso, void *dir, char *name, char *input, int mode = -1);
extern(C) void  isowrite_copy_file(void *iso, void *cdtool, void *dir, char *name, char *input);
extern(C) int   isoread_extract(void *cdutil, char *input, char *output);
extern(C) void  isowrite_copy_dir(void *iso, void *cdutil, void *dir, char *name, char *input = null, int mode = -1, char *checkdir = null);
extern(C) void  isowrite_create_cue(void *iso, char *cue, char *bin);
extern(C) int   isoread_exists(void *cdutil, char *input);

extern(Windows) {
	int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
	int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUsedDefaultChar);
	uint GetACP();
}

wchar[] sjis_convert_utf16(char[] data) { return convert_to_utf16(data, 932); }
char[] sjis_convert_utf8(char[] data) { return std.utf.toUTF8(sjis_convert_utf16(data)); }

wchar[] convert_to_utf16(char[] data, int codepage) {
	wchar[] out_data = new wchar[data.length * 4];
	int len = MultiByteToWideChar(
		codepage,
		0,
		data.ptr,
		data.length,
		out_data.ptr,
		out_data.length
	);
	return out_data[0..len];
}

char[] convert_from_utf16(wchar[] data, uint codepage) {
	char[] out_data = new char[data.length * 4];
	int len = WideCharToMultiByte(
		codepage,
		0,
		data.ptr,
		data.length,
		out_data.ptr,
		out_data.length,
		null,
		null
	);
	return out_data[0..len];
}

char[] mb_convert_encoding(char[] str, int to_codepage, int from_codepage) {
	return convert_from_utf16(convert_to_utf16(str, from_codepage), to_codepage);
}

uint charset_to_codepage(char[] charset) {
	charset = replace(std.string.tolower(strip(charset)), "-", "_");
	switch (charset) {
		case "shift_jis": return 932;
		case "utf_16": return 1200;
		case "utf_32": return 12000;
		case "utf_7": return 65000;
		case "utf_8": return 65001;
		case "windows_1252", "latin_1", "iso_8859_1": return 1252;
		default: throw(new Exception("Unknown charset '" ~ charset ~ "'"));
	}
}

char[] mb_convert_encoding(char[] str, char[] to_encoding, char[] from_encoding) {
	return mb_convert_encoding(str, charset_to_codepage(to_encoding), charset_to_codepage(from_encoding));
}

enum {
	MODE0       = 0,
	MODE1       = 1,
	MODE2       = 2,
	MODE2_FORM1 = 3,
	MODE2_FORM2 = 4,
	MODE_RAW    = 5,
	GUESS       = 6,
}

class IsoDirectory {
	IsoBuilder iso;
	private void *handle;
	char[] path;
	
	this(IsoBuilder iso, void *handle, char[] path) {
		this.iso = iso;
		this.handle = handle;
		this.path = path;
	}
	
	IsoDirectory createDir(char[] name) {
		return iso.createDir(this, name);
	}
	
	void createFile(char[] name, char[] input, int mode = -1) {
		iso.createFile(this, name, input, mode);
	}

	void createFile(char[] name, ubyte[] data) {
		auto tmpname = "__TEMP__";
		std.file.write(tmpname, data);
		createFile(name, tmpname);
		try { std.file.remove(tmpname); } catch (Exception e) { }
	}

	void createFile(char[] name, Stream stream) {
		auto sstream = new SliceStream(stream, 0);
		createFile(name, cast(ubyte[])sstream.readString(sstream.size));
	}

	void copyFile(char[] name, char[] input = null) {
		if (input is null) input = path ~ name;
		iso.copyFile(this, name, input);
	}
	
	void copyDir(char[] name, char[] input = null, int mode = -1, char[] checkpath = null) {
		if (input is null) input = path ~ name;
		iso.copyDir(this, name, input, mode, checkpath);
	}
}

char* utf8ToCCPStringz(char[] str) {
	return toStringz(mb_convert_encoding(str, GetACP, 65001));
}

class IsoBuilder {
	IsoDirectory root;
	private void *handle_w;
	private void *handle_r;
	char[] output;
	
	this(char[] input, char[] output) {
		handle_r = isoread_open(utf8ToCCPStringz(input));
		handle_w = isowrite_open(utf8ToCCPStringz(output));
		root = new IsoDirectory(this, isowrite_isoread_copy_basics(this.handle_w, this.handle_r), "/");
		this.output = output;
	}
	
	~this() {
		isowrite_create_cue(this.handle_w, utf8ToCCPStringz(getName(output) ~ ".cue"), utf8ToCCPStringz(getBaseName(output)));

		isowrite_close(handle_w);
		isoread_close(handle_r);
	}
	
	IsoDirectory createDir(IsoDirectory dir, char[] name) {
		return new IsoDirectory(this, isowrite_create_dir(this.handle_w, dir.handle, utf8ToCCPStringz(name)), dir.path ~ name ~ "/");
	}
	
	void createFile(IsoDirectory dir, char[] name, char[] input, int mode = -1) {
		isowrite_create_file(this.handle_w, dir.handle, utf8ToCCPStringz(name), utf8ToCCPStringz(input), mode);
	}

	void createFile(IsoDirectory dir, char[] name, ubyte[] data) {
		auto tmpname = "__TEMP__";
		std.file.write(tmpname, data);
		isowrite_create_file(this.handle_w, dir.handle, utf8ToCCPStringz(name), utf8ToCCPStringz(tmpname));
		try { std.file.remove(tmpname); } catch (Exception e) { }
	}

	void copyFile(IsoDirectory dir, char[] name, char[] input) {
		isowrite_copy_file(this.handle_w, this.handle_r, dir.handle, utf8ToCCPStringz(name), utf8ToCCPStringz(input ~ ";1"));
	}
	
	void copyDir(IsoDirectory dir, char[] name, char[] input, int mode = -1, char[] checkpath = null) {
		isowrite_copy_dir(this.handle_w, this.handle_r, dir.handle, utf8ToCCPStringz(name), utf8ToCCPStringz(input), mode, utf8ToCCPStringz(checkpath));
	}
	
	bool extractFile(char[] input, char[] output) {
		return isoread_extract(this.handle_r, utf8ToCCPStringz(input ~ ";1"), utf8ToCCPStringz(output)) != 0;
	}
	
	bool exists(char[] input) {
		return isoread_exists(this.handle_r, utf8ToCCPStringz(input ~ ";1")) != 0;
	}
}