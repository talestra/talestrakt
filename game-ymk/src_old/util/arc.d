module yume.arc;

import std.stdio, std.string, std.stream, std.file, std.path;

class ARC {
	static void process(char[] fin, void delegate(char[], char[], char[], Stream) process = null) {
		uint ext_count;
		scope auto sfin = new BufferedFile(fin, FileMode.In);
		sfin.read(ext_count);
		for (int n = 0; n < ext_count; n++) {
			uint count, start;
			char[] ext = std.string.toString(toStringz(sfin.readString(4)));
			sfin.read(count);
			sfin.read(start);
			
			scope auto sfinf = new SliceStream(sfin, start);
			
			for (int m = 0; m < count; m++) {
				uint len, pos;
				char[] bname = std.string.toString(toStringz(sfinf.readString(9)));
				sfinf.read(len);
				sfinf.read(pos);
				
				if (process) process(bname ~ "." ~ ext, bname, ext, new SliceStream(sfin, pos, pos + len));
			}
		}
	}

	static void extract(char[] fin) {
		process(fin, delegate void(char[] fname, char[] name, char[] ext, Stream sin) {
			writefln("%s", fname);
			try { mkdir("data"); } catch { }
			try { mkdir("data/" ~ ext); } catch { }
			scope auto sout = new File("data/" ~ ext ~ "/" ~ fname, FileMode.OutNew);
			sout.copyFrom(sin);
			sout.close();
		});
	}

	static void create(char[] fout, char[][] files, Stream delegate(char[], char[], char[]) open = null) {
		class FENTRY {
			char[] name, ext;
			uint epos;
			this(char[] name, char[] ext) { this.name = name; this.ext = ext; }
		}

		FENTRY[][char[]] files_ext;
		scope Stream sout = new File(fout, FileMode.OutNew);// scope (exit) { sout.close(); delete sout; }
		
		foreach (file; files) {
			file = toupper(strip(file));
			int pos = find(file, ".");
			if (pos == -1) throw(new Exception("File without extension!"));
			files_ext[file[pos + 1..file.length]] ~= new FENTRY(file[0..pos], file[pos + 1..file.length]);
		}
		
		int nexts = files_ext.keys.length;
		
		int cptr = 4 + 12 * nexts;
		
		sout.write(cast(uint)nexts);
		foreach (cext; files_ext.keys.sort) {
			ubyte[4] cext_d; cext_d[0..cext.length] = cast(ubyte[])cext;
			sout.write(cext_d);
			sout.write(cast(uint)files_ext[cext].length);
			sout.write(cast(uint)cptr);
			cptr += 17 * files_ext[cext].length;
		}
		
		FENTRY[] p_entries;
		
		foreach (cext; files_ext.keys.sort) {
			foreach (fentry; files_ext[cext]) {
				ubyte[9] cename; cename[0..fentry.name.length] = cast(ubyte[])fentry.name;
				sout.write(cename);
				fentry.epos = sout.position;
				sout.write(cast(uint)0);
				sout.write(cast(uint)0);
				p_entries ~= fentry;
			}
		}
		
		foreach (entry; p_entries) {
			char[] fname = entry.name ~ "." ~ entry.ext;

			int start = sout.position;
			
			Stream s = open ? open(fname, entry.name, entry.ext) : (new BufferedFile(fname, FileMode.In));
				scope ubyte[] data = new ubyte[0x100000];
				while (!s.eof) sout.write(data[0..s.read(data)]);
				delete data;
			s.close();

			int end = sout.position;
			
			auto ss = new SliceStream(sout, entry.epos, 8);
			ss.write(cast(uint)(end - start));
			ss.write(cast(uint)(start));
		}
	}
}
