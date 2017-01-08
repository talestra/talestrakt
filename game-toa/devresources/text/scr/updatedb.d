import std.stdio, std.stream, std.file, std.string, std.process, std.c.stdlib;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp, sqlite3;

Sqlite3 db;

int main(char[][] args) {
	db = new Sqlite3("translation.db");
	
	db.performQuery("BEGIN TRANSACTION;");
	db.performQuery("UPDATE texts SET t2=t1,translated='false';");
	db.performQuery("END TRANSACTION;");
	
	db.performQuery("BEGIN TRANSACTION;");

	foreach (e; listdir("SRC")) {	
		if (e.length < 4) continue;
		if (e[e.length-4..e.length] != ".txt") continue;
		auto result = db.query("SELECT id FROM files2 WHERE name=?", [e[0..e.length-4]]);
		if (!result.more) continue;			
		int fid = result.getInt32(0);
		
		delete result;
		
		writefln(e);
		auto ps = GetTextPointers(new File(std.string.format("SRC/%s", e), FileMode.In));

		foreach (p, t; ps) {
			db.performQuery("UPDATE texts SET t2=?,translated='true' WHERE id=(SELECT tid FROM entries2 WHERE fid=? AND pid=?);", [t, std.string.toString(fid), std.string.toString(p)]);
		}		
	}
	
	db.performQuery("END TRANSACTION;");

	delete db;
	
	return 0;
}
