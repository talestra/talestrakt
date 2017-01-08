import imports;

import pfs, check;

/*const char[][] list = [
	"AS_009.sfd", // Credits + Ending
	"AS_002.sfd", // Intro
	"AS_003.sfd", // Asch & Luke
	"AS_004.sfd", // Cortándose el pelo
	"AS_006.sfd", // Van derrotado (I)
	"AS_007.sfd", // Muerte de Asch
	"AS_008.sfd", // Luke & Asch & Lorelei
	"AS_001.sfd", // Opening
];*/

class MovieDeCrypt : FilterStream {
	this(Stream s) { super(s); }
	override size_t readBlock(void* buffer, size_t size) {
		long c = position;
		auto r = super.readBlock(buffer, size);
		ubyte[] data; data = (cast(ubyte *)buffer)[0..r];
		
		ubyte *ptr = data.ptr;
		for (int n = 0, l = data.length; n < l; n++, ptr++, c++) *ptr = ~((*ptr ^ 0b01100110) + (c % 277));
		
		return r;
	}
}

void process() { scope(exit)Progress.pop;Progress.push("Traduciendo vídeos");
	PFS pfs;
	try {
		if (check.isUNDUB) {
			pfs = new PFS(new MovieDeCrypt(new BufferedFile("toa-spa-movies-undub.pak")));
		} else {
			pfs = new PFS(new MovieDeCrypt(new BufferedFile("toa-spa-movies.pak")));
		}
	} catch (Exception e) {
		writefln("error-movie: %s", e.toString);
		writefln("skipping");
		return;
	}

	int k = 0, len = pfs.list.length;

	foreach (e; pfs) { patch_stopPoint();
		Progress.set(k, len, e.name);
		FS.gout["mov/" ~ e.name].replace(e, false);
		k++;
	}
	Progress.set(len, len);
	
	/*
	foreach (k, name; list) { patch_stopPoint();
		Progress.set(k, list.length, name);
		if (!FS.movie[name].exists) writefln("Vídeo 'movie/%s' no existe", name);
		try {
			FS.gout["mov/" ~ name].replace(FS.movie[name], false);
		} catch (Exception e) {
			writefln("\nmovie_error: '%s'\n", e.toString);
		}
	}
	*/
}