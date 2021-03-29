import std.stdio, std.stream, std.file, std.string, std.process;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp;
import std.c.string, std.c.time;

bool[char[]] blacklist;

bool initializated = false;

void init() {
	if (initializated) return;
	AbyssInitIsoPath();
	blacklist["CHP_T00E"] = true;
	blacklist["COK_D02"] = true;
	blacklist["ICE_D04E"] = true;
	blacklist["SHI_D00E"] = true;
	blacklist["TESTMAP"] = true;
	blacklist["GRA_D00"] = true;
	initializated = true;
}

void process_SB7(char[] name) {
	writefln("%s", name);
}

char[][char[]] translate;

char[] normalize_str(char[] str) {
	return std.string.replace(std.string.strip(str), "\r", "");
}

void get_translate_table() {
	if (!std.file.exists("translate.dat")) {
		Stream output = new File("translate.dat", FileMode.OutNew);
		foreach (file; listdir("trans/o")) {
			writefln("get_translate_table: %s", file);
			char[][int] o = GetTextPointers(new File("trans/o/" ~ file));
			char[][int] t = GetTextPointers(new File("trans/t/" ~ file));
			foreach (k; o.keys) {
				output.write(normalize_str(o[k]));
				output.write(normalize_str(t[k]));
			}
		}
		output.close();
	}
	
	Stream input = new File("translate.dat", FileMode.In);
	while (!input.eof) {
		char[] o, t;
		input.read(o);
		input.read(t);
		translate[o] = t;
	}
	
	translate = translate.rehash;	
}

void process_SB7() {
	foreach (file; listdir("SB7")) {
		writefln("process_SB7: %s", file);
		Stream sb7_s = new File("SB7/" ~ file, FileMode.In);
		Stream txt_s = new File("TXT/" ~ file ~ ".txt", FileMode.OutNew);
		SB7 sb7 = new SB7(sb7_s);

		foreach (id, e; sb7.list) {
			char[] s = normalize_str(e.text), ts;
			//writefln(e.params);
			//if (id <= 96) continue;
			if (!s.length) continue;
			if (s.length >= 7 && s[0..7] == "motion:") continue;
			//tl.Insert(s, name, id, e.params);
			
			if (s in translate) {
				ts = translate[s];
			} else {
				ts = s;
			}
			
			txt_s.writef("## POINTER %d\n", id);
			txt_s.writeExact(ts.ptr, ts.length);
			txt_s.writef("\n\n");
			
			if (!(s in translate)) {
				writefln("No translation: %s", s);
				/*
				char[] ss = "\x3C\x53\x50\x45\x45\x43\x48\x2A\x3E\x49\x74\x20\x73\x65\x65\x6D\x73\x20\x6C\x69\x6B\x65\x20\x70\x65\x6F\x70\x6C\x65\x20\x61\x72\x65\x20\x64\x79\x69\x6E\x67\x20\x0A\x72\x69\x67\x68\x74\x20\x61\x66\x74\x65\x72\x20\x68\x65\x61\x72\x69\x6E\x67\x20\x74\x68\x65\x20\x4F\x72\x64\x65\x72\x0A\x6F\x66\x20\x4C\x6F\x72\x65\x6C\x65\x69\x20\x72\x65\x61\x64\x20\x74\x68\x65\x20\x53\x63\x6F\x72\x65\x2E";
				
				if (s != ss) {
					for (int n = 0; n < ss.length; n++) {						
						if (ss[n] != s[n]) {
							writefln("['%02X' != '%02X']", ss[n], s[n]);
							break;
						} else {
							printf("%c", s[n]);							
						}
					}
					//writefln("'%s'\n'%s'", s, ss);
				}
				
				return;
				*/
			}
			//txt_s.writef("");
			
			//printf("%d: %s\n\n", id, toStringz(s));
		}
		
		txt_s.close; delete txt_s;
		sb7_s.close; delete sb7_s;		
		delete sb7;
	}
}

void extract_FS2() {
	init();
	//Iso isomap = new Iso("to7MAP.cvm"); return;
	
	//return;
	
	foreach (e; isomap) { std.gc.genCollect();
		//writefln(e.name);
	
		if (!e.isFile) continue;

		// Comprueba extension
		char[] ext = e.name[e.name.length - 3..e.name.length];		
		if (ext != "PKB") continue;
		
		// Obtiene id
		char[] id = e.name[0..e.name.length - 4];
		
		// Comprueba si esta en la lista negra
		if (id in blacklist) continue;
		
		// Obtiene nombres locales para ficheros
		char[] PKB = std.string.format("PKB/%s.PKB", id);
		char[] FS2 = std.string.format("FS2/%s.FS2", id);
		char[] SB7 = std.string.format("SB7/%s.SB7", id);
		
		//writefln(id);
		
		if (!std.file.exists(PKB) || !std.file.exists(FS2) || !std.file.exists(SB7)) {
			writef("%s...", id);
			
			if (!std.file.exists(PKB)) {
				File f = new File(PKB, FileMode.OutNew);
				f.copyFrom(e.open);
				e.close(); f.close();
				delete f;
			}
			
			if (!std.file.exists(FS2)) {			
				ubyte[] input = cast(ubyte[])read(PKB);
				ubyte[] output;
				
				try {
					output = cast(ubyte[])DecodeBuffer(input);				
				} catch (Exception e) {
					output = input;
				}

				write(FS2, output);
				
				delete input;
				delete output;
				
			}
			
			if (!std.file.exists(SB7)) {				
				try {
					Fps2Archive fa = new Fps2Archive(FS2);

					foreach (e; fa) {
						if (e.type != "sb7") continue;
						Stream s = new File(format("SB7/%s.SB7", id), FileMode.OutNew);
						s.copyFrom(e.open);
						e.close();
						s.close();
						delete s;
						break;
					}

					fa.close();
					delete fa;
				} catch (Exception e) {
					writefln("ERROR WITH: %s\n%s", id, e.toString);
				}
			}
			writefln("Ok");
		}
	}
}
	
int main(char[][] args) {
	get_translate_table;
	extract_FS2();
	process_SB7();
	return 0;
}
