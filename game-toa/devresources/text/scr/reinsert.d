import std.stdio, std.stream, std.file, std.string, std.date, std.process;
import tales.util.gameformat, tales.common;
import tales.scont.generic, tales.scont.iso, tales.scont.fps2;
import tales.isopath, tales.comp, tales.sb7;
import tales.util.rangelist;
import sqlite3;

version = alignfake;

version(alignfake) {
	alias StreamWriteStringR2Fake StreamWriteStringR2Final;
} else {
	alias StreamWriteStringR2 StreamWriteStringR2Final;
}

Sqlite3 db;

int main(char[][] args) {
	AbyssInitIsoPath();
	
	bool tdev = true;

	db = new Sqlite3("translation.db");

	writefln("Starting...");
	
	char[] id = "CAP_I06_02";
	
	int i = 0;
	foreach (e; isomap) { //std.gc.fullCollect();
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];
		//writefln(id);

		if (id == "CHP_T00E") continue;
		if (id == "COK_D02") continue;
		if (id == "ICE_D04E") continue;
		if (id == "MAP") continue;
		if (id == "SHI_D00E") continue;

		writef("%s...", id);
		
		if (std.file.exists("MOD/" ~ id ~ ".PKB")) {
			writefln("Exists");
			continue;
		}
		
		if (tdev) printf("[1]");

		try { mkdir("MOD"); } catch (Exception e) { }

		//(new File(id ~ ".PKB", FileMode.OutNew)).copyFrom(e.open);

		//Fps2Archive fps2 = new Fps2Archive(new CompressedStream(new File(std.string.format("PKB/%s.PKB", id))));
		File fps2f = new File(std.string.format("PKB/%s.FS2", id));
		Fps2Archive fps2 = new Fps2Archive(fps2f);
		
		if (tdev) printf("[2]");
		
		Stream[] fsl = [];
		
		foreach (_e; fps2) { Fps2Entry e = cast(Fps2Entry)_e;
			if (e.type != "sb7") continue;

			auto result = db.query("SELECT e.pid,t.t2 FROM entries AS e LEFT JOIN texts AS t ON (e.tid=t.id) WHERE e.fid=(SELECT id FROM files WHERE name=?) ORDER BY e.pid ASC;", [id]);

			Stream sb7s = e.open;
			PatchedMemoryStream sb7sn = new PatchedMemoryStream();			
			sb7sn.copyFrom(sb7s);
			sb7sn.noptr();
			SB7 sb7 = new SB7(sb7s);
			sb7s.position = 0;

			while (result.more) {
				sb7.list[result.getInt32(0)].text = result.getText(1);
				char[] s = result.getText(1);
				result.step();
			}

			sb7.update(sb7sn);
			e.setStream(sb7sn);
			fsl ~= sb7sn;

			delete sb7;
			delete result;			
		}
		
		if (tdev) printf("[6]");
		
		//CompressStream dump = new CompressStream(new File("MOD/" ~ id ~ ".PKB", FileMode.OutNew));
		File dump = new File("MOD/" ~ id ~ ".B", FileMode.OutNew);
		
		//dump.noptr();
				
		fps2.saveto(dump);		
		
		if (tdev) printf("[7]");
	
		dump.close();
		
		delete dump;
		
		system("..\\..\\util\\script\\comptoe.exe -s -c3 MOD\\" ~ id ~ ".B MOD\\" ~ id ~ ".PKB");
		
		if (tdev) printf("[8]");
		
		std.file.remove("MOD/" ~ id ~ ".B");
		
		foreach (e; fps2) { e.close(); delete e; }				
		fps2.close(); delete fps2;
		fps2f.close(); delete fps2f;
		
		foreach (s; fsl) { s.close(); delete s; }
		delete fsl;

		writefln("Ok");
		
		std.gc.genCollect();
		//break;
	}

	return 0;
}
