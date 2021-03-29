import std.stdio, std.stream, std.file, std.string, std.date, std.conv, std.process;
import tales.util.gameformat, tales.common;
import tales.scont.generic, tales.scont.iso, tales.scont.fps2, tales.scont.fps3;
import tales.isopath, tales.comp, tales.sb7, sqlite3;
import tales.util.rangelist;

void CreateScript() {
	writefln("Starting...");
	
	//Fps2Archive fps2 = new Fps2Archive(new File(std.string.format("PKB/%s.FS2", id))); fps2.saveto(std.string.format("mod/%s.FS2.MOD", id)); return 0;

	char[] path = "TO7/MAP";

	//foreach (e; listdir(path)) {
		//e = "AJI_D00E.PKB";
	foreach (e; isomap) {
		if (!e.isFile) continue;
		writef("%s...", e.name);
		//writef("%s...", e);
		
		//Stream oc = new File(path ~ "/" ~ e, FileMode.In);
		Stream oc = e.open;
		Stream ou = new CompressedStream(oc);

		Stream mu = new File("TEST.PKB", FileMode.OutNew);
		Stream mc = new CompressStream(mu);
		
		/*try {
			DecodeStream(oc, mu);
		} catch (Exception e) {
		}*/
		
		mc.copyFrom(ou);
		
		mc.close(); delete mc;
		
		mu.close(); delete mu;
		
		ou.close(); delete ou;
		
		oc.close(); delete oc;
		
		printf("Ok\n");
		
		std.gc.genCollect();
		//break;
		//std.gc.fullCollect();
	}

	return;

	
	foreach (e; isomap) {
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];
		
		if (id == "CHP_T00E") continue;
		if (id == "COK_D02") continue;
		if (id == "ICE_D04E") continue;
		if (id == "MAP") continue;
		if (id == "SHI_D00E") continue;		
		
		Stream oc = isomap[std.string.format("%s.PKB", id)].open;
		Stream ou = new CompressedStream(oc);
		
		printf("%s...", toStringz(id));
		
		{	
			Stream mu = new File("temp.PKB", FileMode.OutNew);
			//Stream mc = new CompressStream(mu);
			
				//mc.copyFrom(ou);
				//mu.copyFrom(ou);
				mu.copyFrom(oc);
			
			//mc.close(); delete mc;			
			mu.close(); delete mu;			
		}
		
		ou.close(); delete ou;
		oc.close(); delete oc;
		
		std.gc.genCollect();
		
		printf("Ok\t\t\r");
	}
	
	return;

	/*
	Sqlite3 db = new Sqlite3("SCR/translation.db");

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
			
		//char[] oname = "TO7/MAP/" ~ id ~ ".PKB";
		char[] oname = "temp.PKB";
		
		//if (std.file.exists(oname)) continue;

		writef("%s...", id);
		
		void doEntry() {
			Stream fps2s;
			Stream cpkb = isomap[std.string.format("%s.PKB", id)].open;
			ubyte type;
			cpkb.read(type);
			cpkb.position = 0;		
			fps2s = (type < 5) ? (new CompressedStream(cpkb)) : cpkb;
	
			Fps2Archive fps2 = new Fps2Archive(fps2s);
			
			Stream sb7s, sb7sn;
			
			foreach (_e; fps2) { Fps2Entry e = cast(Fps2Entry)_e;
				if (e.type != "sb7") continue;
	
				auto result = db.query("SELECT e.pid,t.t2 FROM entries AS e LEFT JOIN texts AS t ON (e.tid=t.id) WHERE e.fid=(SELECT id FROM files WHERE name=?) ORDER BY e.pid ASC;", [id]);
	
				sb7s = e.open;
				sb7sn = new MemoryStream();
				sb7sn.copyFrom(sb7s);
				SB7 sb7 = new SB7(sb7s);
				sb7s.position = 0;
	
				while (result.more) {
					sb7.list[result.getInt32(0)].text = result.getText(1);
					result.step();
				}
	
				sb7.update(sb7sn);
				e.setStream(sb7sn);
				//(new File("test.sb7", FileMode.OutNew)).copyFrom(sb7sn);
			}
	
			makedir("TO7/MAP");
			Stream dump = new CompressStream(new File(oname, FileMode.OutNew));
			fps2.saveto(dump);
			dump.close();
			
			delete dump;
			delete fps2;
			delete sb7s;
			delete sb7sn;
			
			try { delete cpkb; } catch (Exception e) { }
			try { delete fps2s; } catch (Exception e) { }
		}
		
		doEntry();
		
		std.gc.genCollect();
		//std.gc.fullCollect();

		printf("Ok\t\t\r");
		//break;
	}*/
}

int main(char[][] args) {
	AbyssInitIsoPath();	
	CreateScript();
	
	return 0;
}
