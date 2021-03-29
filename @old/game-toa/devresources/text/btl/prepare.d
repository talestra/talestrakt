import std.stdio, std.stream, std.file, std.string, std.process;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp, sqlite3;
import btlcommon;

Sqlite3 db;

int main() {
	TOAGameFormatString fs = new TOAGameFormatString();
	
	int[][int] list;
	list[2] = [0x0100, 0x0264, 0x03C8, 0x052C, 0x0690, 0x0808, 0x09A8, 0x0B0C, 0x0CC0, 0x0E24, 0x0F88, 0x10EC];
	list[3] = [0x0164, 0x02C8, 0x042C, 0x05A4, 0x071C, 0x0920, 0x0A70, 0x0BD4, 0x0D38, 0x0E9C, 0x1000, 0x1164, 0x12C8, 0x142C, 0x1590, 0x16F4, 0x1920, 0x1A84, 0x1BE8, 0x1D4C, 0x1EB0, 0x2014, 0x2178, 0x22DC, 0x2440, 0x25A4, 0x2730, 0x2984, 0x2AE8, 0x2C4C, 0x2DB0, 0x2F14, 0x3078, 0x31DC, 0x3340, 0x34A4, 0x3608, 0x376C, 0x3998, 0x3AFC, 0x3C60, 0x3DC4, 0x3F28, 0x408C, 0x41F0, 0x4354, 0x45A8, 0x470C, 0x4870, 0x49D4, 0x4B38];
	list[5] = [0x01DC, 0x0340, 0x04A4, 0x0608, 0x076C, 0x08D0, 0x0A34, 0x0B98, 0x0CFC, 0x0E74, 0x0FD8, 0x1168, 0x12CC, 0x1430, 0x1594, 0x16F8, 0x1884, 0x19E8, 0x1B88, 0x1CEC, 0x1E50, 0x1FE0, 0x2144, 0x22A8, 0x240C, 0x2570, 0x26FC, 0x2888, 0x29EC, 0x2B8C, 0x2CF0, 0x2E54, 0x2FB8, 0x3130, 0x3294, 0x345C, 0x35D4, 0x3738, 0x389C, 0x3A00];
	
	try { std.file.remove("btsc.db"); } catch (Exception e) { }
	
	db = new Sqlite3("btsc.db");
	
	//try { db.performQuery("CREATE TABLE texts (sid INTEGER, sptr INTEGER, title CHAR(31), text TEXT(255), file CHAR(31));"); } catch (Exception e) { }
	
	//db.performQuery("DELETE FROM texts;");
	
	db.performQuery("BEGIN TRANSACTION;");
	
	foreach (k, cl; list) {
		Stream s = getBTSC(k);
		foreach (ccl; cl) {
			try { db.performQuery("INSERT INTO texts (sid,sptr,title,otext,text,file) VALUES (?,?,?,?,?,?);", [std.string.format(k), std.string.format(ccl), fs.extractStringz(s, ccl), fs.extractStringz(s, ccl + 0x20), fs.extractStringz(s, ccl + 0x20), "BTL_USU.BIN"]); } catch (Exception e) { }
			//try { db.performQuery("UPDATE texts SET otext=? WHERE file=? AND sid=? AND sptr=?;", [fs.extractStringz(s, ccl + 0x20), "BTL_USU.BIN", std.string.format(k), std.string.format(ccl)]); } catch (Exception e) { }
		}
	}
	
	db.performQuery("END TRANSACTION;");
	
	//return 0;
	
	int[][char[]] rlist;
	
	rlist["EP039_BTL00A.BIN"] = [ 0x0924, 0x0AF4, 0x0D48, 0x0F08, 0x1188 ];
	rlist["EP039_BTL00B.BIN"] = [ 0x09E4, 0x0BCC, 0x0E2C, 0x0FBC, 0x114C ];
	rlist["EP039_BTL00C.BIN"] = [ 0x0968, 0x0B24, 0x0D4C, 0x0F38, 0x11D4 ];
	rlist["EP039_BTL00D.BIN"] = [ 0x0718, 0x08A8, 0x0A38, 0x0BC8, 0x0D58, 0x0EE8, 0x1078, 0x12E0 ];
	rlist["EP039_BTL00E.BIN"] = [ 0x07AC, 0x093C, 0x0ACC, 0x0C5C, 0x0E6C, 0x0FFC, 0x123C, 0x13CC, 0x155C, 0x16EC, 0x1954 ];
	rlist["EP039_BTL00F.BIN"] = [ 0x07AC, 0x093C, 0x0ACC, 0x0C5C, 0x0E6C, 0x0FFC, 0x1228, 0x13B8, 0x1620 ];
	rlist["EP039_BTL00G.BIN"] = [ 0x07D8, 0x0994, 0x0B24, 0x0CB4, 0x0EA8, 0x1038, 0x1278, 0x1408, 0x1598, 0x1728, 0x1990 ];
	rlist["EP039_BTL01A.BIN"] = [ 0x04C8, 0x06E0, 0x0924, 0x0B68, 0x0F88, 0x11B4, 0x13BC, 0x15D0, 0x17A4, 0x1978, 0x1B4C, 0x1D20, 0x1FB8, 0x2204, 0x23EC ];
	rlist["EP039_BTL01B.BIN"] = [ 0x0348, 0x058C, 0x07D0, 0x0A14, 0x0E34, 0x1030, 0x121C, 0x145C, 0x166C, 0x1840 ];
	rlist["EP039_BTL01C.BIN"] = [ 0x03D0, 0x0614, 0x0858, 0x0A9C, 0x0EBC, 0x10A4, 0x1234, 0x1474, 0x1604, 0x1814, 0x19E8 ];
	rlist["EP039_BTL01D.BIN"] = [ 0x02D8, 0x051C, 0x0760, 0x0BD4, 0x0D90, 0x0FA0, 0x1174 ];
	rlist["EP039_BTL01E.BIN"] = [ 0x02D8, 0x051C, 0x0760, 0x0BD4, 0x0D90, 0x0FA0, 0x1174 ];
	rlist["EP039_BTL01F.BIN"] = [ 0x02D8, 0x051C, 0x0760, 0x0C00, 0x0E3C, 0x1010 ];
	rlist["EP039_BTL01G.BIN"] = [ 0x02D8, 0x051C, 0x0760, 0x0C00, 0x0DBC, 0x0FCC, 0x11A0 ];
	rlist["EP039_BTL02A.BIN"] = [ 0x0370, 0x052C, 0x06A8, 0x0864, 0x0A20, 0x0D14, 0x0F0C ];
	rlist["EP039_BTL02B.BIN"] = [ 0x0370, 0x052C, 0x06D4, 0x0864, 0x0A20, 0x0D14, 0x0F0C ];
	rlist["EP039_BTL02C.BIN"] = [ 0x0370, 0x052C, 0x06A8, 0x0864, 0x0A20, 0x0D14, 0x0F0C ];
	

	db.performQuery("BEGIN TRANSACTION;");
	
	foreach (k, cl; rlist) {
		Stream s = new File("EP039/" ~ k, FileMode.In);
		foreach (ccl; cl) {
			//writefln(fs.extractStringz(s, ccl));
			try { db.performQuery("INSERT INTO texts (sid,sptr,title,otext,text,file) VALUES (?,?,?,?,?,?);", [std.string.format(0), std.string.format(ccl), fs.extractStringz(s, ccl), fs.extractStringz(s, ccl + 0x20), fs.extractStringz(s, ccl + 0x20), k]); } catch (Exception e) { writefln(e.toString); }
			//writefln("INSERT INTO texts (sid,sptr,title,otext,text,file) VALUES (?,?,?,?,?,?);", [std.string.format(0), std.string.format(ccl), fs.extractStringz(s, ccl), fs.extractStringz(s, ccl + 0x20), fs.extractStringz(s, ccl + 0x20), k]);
		}
		s.close();
		//ep039
		/*
		Stream s = getBTSC(k);
		foreach (ccl; cl) {
			try { db.performQuery("INSERT INTO texts (sid,sptr,title,text,file) VALUES (?,?,?,?,?);", [std.string.format(k), std.string.format(ccl), fs.extractStringz(s, ccl), fs.extractStringz(s, ccl + 0x20), "BTL_USU.BIN"]); } catch (Exception e) { }
		}
		*/
	}
	
	db.performQuery("END TRANSACTION;");
	
	return 0;	
}

/*

*/
