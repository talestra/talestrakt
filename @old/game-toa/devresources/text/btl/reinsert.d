import std.stdio, std.stream, std.file, std.string, std.process;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp, sqlite3;
import btlcommon;

Sqlite3 db;

void ReinsertText() {
	ubyte clear[0x100 + 0x20];
	TOAGameFormatString fs = new TOAGameFormatString();
	
	db = new Sqlite3("btsc.db");
	
	Sqlite3Result dids;
	
	void patchResult(Stream s, Sqlite3Result res) {
		foreach (row; res) {
			int pos = res.getInt32(0);
			printf("  %04X\n", pos);
			s.position = pos; s.write(clear);
			s.position = pos + 0x000; s.writeString(fs.encodeString(
				std.string.replace(res.getText(1), "\r", "")
			));
			s.position = pos + 0x020; s.writeString(fs.encodeString(
				std.string.replace(res.getText(2), "\r", "")
			));
		}		
	}
	
	if (true) {
		for (dids = db.query("SELECT DISTINCT sid FROM texts WHERE file=?;", ["BTL_USU.BIN"]); dids.more; dids.next()) {
			int id = dids.getInt32(0);
			
			printf("%d\n", id);
			
			Stream s = getBTSC(id);
			
			writefln("  Available: %d", s.available);
			
			//writefln("ID:", id);
			
			auto res = db.query("SELECT sptr,title,text FROM texts WHERE sid=? AND file=?;", [std.string.format(id), "BTL_USU.BIN"]);
			patchResult(s, res);
		}
	}
	
	if (true) {
		for (dids = db.query("SELECT DISTINCT file FROM texts WHERE file!=?;", ["BTL_USU.BIN"]); dids.more; dids.next()) {
			auto file = dids.getText(0);
			Stream s = new File("ep039/" ~ file, FileMode.In | FileMode.Out);
	
			auto res = db.query("SELECT sptr,title,text FROM texts WHERE file=?;", [file]);
			patchResult(s, res);
			
			s.close();
		}
	}
}

void ReinsertImage() {
	int count = 4;
	int header;
	
	Stream s = new CompressStream(getBtlImageStream());
	
	s.position = 0;
	s.write(count);
	for (int n = 0; n < count; n++) {
		s.write(cast(int)0);
	}
	
	while ((s.position % 0x20) != 0) s.write('\xFE');
	
	//s.position = (header = 4 + count * 4);
	for (int n = 0; n < count; n++) {
		Stream f;
		
		printf("  %d\n", n);
		
		if (n == 2) {
			f = new File("2.mod.tm2");
		} else {
			if (n == 4) {
				f = new MemoryStream();
				f.writeString(x"0D0A0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
				f.position = 0;
			} else {
				f = new File(std.string.format("%d.tm2", n));
			}
		}
		
		//f = new File(std.string.format("%d.tm2", n));
		
		uint bpos = s.position;
		s.position = 4 + n * 4;
		s.write(bpos);
		s.position = bpos;
		s.copyFrom(f);
	}
	
	printf("  finalizando...");
	
	s.close();
	
	printf("Ok\n");
	
	//new CompressStream();
}

int main() {
	printf("ReinsertText...\n");
	ReinsertText();
	printf("ReinsertImage...\n");
	ReinsertImage();
	
	return 0;	
}