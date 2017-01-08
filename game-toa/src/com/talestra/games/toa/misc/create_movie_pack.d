import std.stdio, std.string, std.stream;

void copy2From(Stream to, Stream from, bool restore = true) {
	ubyte[] buf;
	try {
		buf.length = 0x400000;
		long bpos;
		
		if (restore) {
			bpos = from.position;
			from.position = 0;
		}
		
		while (!from.eof) {
			size_t m = from.readBlock(buf.ptr, buf.length);
			to.writeExact(buf.ptr, m);
		}
		
		if (restore) from.position = bpos;
	} finally {
		delete buf;
		buf = null;
	}
}

char[][] files = [
	"AS_001.sfd",
	"AS_002.sfd",
	"AS_003.sfd",
	"AS_004.sfd",
	"AS_006.sfd",
	"AS_007.sfd",
	"AS_008.sfd",
	"AS_009.sfd",
];

class MovieCrypt : FilterStream {
	this(Stream s) { super(s); }
	override size_t writeBlock(void* buffer, size_t size) {
		ubyte[] data; data.length = size; data[0..size] = (cast(ubyte *)buffer)[0..size];
		
		ubyte *ptr = data.ptr;
		for (int n = 0, l = data.length, c = position; n < l; n++, ptr++, c++) *ptr = (~*ptr - (c % 277)) ^ 0b01100110;
		
		return super.writeBlock(data.ptr, data.length);
	}
}

void main() {
	uint[uint] patches;
	Stream s = new MovieCrypt(new File("toa-spa-movies.pak", FileMode.OutNew));
	//Stream s = new File("toa-spa-movies.pak", FileMode.OutNew);
	
	s.writeString("Tales Translations - soywiz - 2008 :3");
	int start_pos = s.position;
	s.write(cast(uint)0);
	
	int files_count = 0;
	foreach (k, file; files) {
		if (!std.file.exists("movie/" ~ file)) {
			continue;
		}
		patches[k] = s.position;
		s.write(cast(uint)0);
		s.write(cast(uint)0);
		s.write(cast(ubyte)0);
		s.write(file);
		files_count++;
	}
	
	foreach (k, file; files) {
		if (!std.file.exists("movie/" ~ file)) {
			writefln("Doesn't exists 'movie/" ~ file ~ "'");
			continue;
		}
		long start = s.position;
		Stream sin = new BufferedStream(new File("movie/" ~ file));
		copy2From(s, sin);
		//s.copyFrom(sin);
		sin.close();
		long end = s.position;
		s.position = patches[k];
		s.write(cast(uint)start);
		s.write(cast(uint)(end - start));
		s.position = end;
		s.flush();
	}
	
	s.position = start_pos;
	s.write(cast(uint)files_count);
}