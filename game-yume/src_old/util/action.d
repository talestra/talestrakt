//////////////////////
// Yume miru kusuri //
//////////////////////
module yume.extract;

import std.stdio, std.string, std.stream, std.file, std.system, std.process;
import yume.util, yume.script, yume.arc, yume.image;

// ROR  ...
// D2C8 884424038A442403
// 9090

version = graph_clean;

void script_decompile_all(char[] folder = "WS", char[] archive = "Rio.en.arc") {
	try { mkdir(folder); } catch { }
	ARC.process(archive, delegate void(char[] file, char[] bname, char[] ext, Stream stream) {
		writefln("%s", file);
		try {
			auto sr = new ScriptReader(stream, file);
			sr.saveto = folder ~ "/" ~ file[0..file.length - 1];
			sr.process();
			delete sr;
		} catch (Exception e) {
			writefln("ERROR2: %s at %s", e.toString, file);
		}
		//break;
	});
}

void extract_arc(char[] name) {
	auto abname = name;
	try { mkdir("DATA"); } catch { }
	try { mkdir("DATA/" ~ abname); } catch { }
	ARC.process(name, delegate void(char[] file, char[] bname, char[] ext, Stream stream) {
		printf("%s...", toStringz(file));
		ubyte[] data;
		ubyte[] temp = new ubyte[0x10000];
		while (!stream.eof) data ~= temp[0..stream.read(temp)];
		delete temp;
		if (ext == "WSC") Data.decrypt(data);
		std.file.write("DATA/" ~ abname ~ "/" ~ file, data);
		printf("Ok\n");
	});
}

void graph_gen() {
	auto f = new File("graph.dot", FileMode.OutNew);

	f.writefln("digraph SCRIPT {");
	//f.writefln("\tsize=\"20,200\"");
	f.writefln("\tsize=\"20,100\"");
	f.writefln("\tconcentrate=true");
	f.writefln("\tratio=compress;");
	f.writefln("\tfontname=Arial;");
	//f.writefln("ratio = \"auto\"");
	//f.writefln("mincross = 2.0");
	
	f.writefln("\tnode [style=filled,arrowsize=0.2,fontsize=12];");
	
	bool[char[]] scripts;
	
	char[] normalize(char[] s) {
		return toupper(s);
	}
	
	bool[char[]] blacklist, blacklist_to, blacklist_from, end_script, multiple_script;
	blacklist["EVEXEC"] = true;
	blacklist["EVMODE"] = true;
	blacklist["EVRET"] = true;
	blacklist["RESTBGM"] = true;
	blacklist["BRAND"] = true;

	blacklist_to["MAINMENU"] = true;

	ARC.process("Rio.en.arc", delegate void(char[] file, char[] bname, char[] ext, Stream stream) {
		bname = normalize(bname);

		writefln("%s", file);
		
		version (graph_clean) {
			if (bname.length >= 2 && bname[0..2] == "EV") blacklist[bname] = true;
			
			if (bname in blacklist) return;
			if (bname in blacklist_from) return;
		}
		
		//scripts[bname] = true;
		//if (bname[0] != 'T') return;
		try {
			auto sr = new ScriptReader(stream, file);
			sr.process();
			int count;
			foreach (sl; sr.script_links.keys) { sl = normalize(sl);
				version (graph_clean) {
					if (sl == "MAINMENU") end_script[bname] = true;
				
					if (sl in blacklist) continue;
					if ((bname != "START") && (sl in blacklist_to)) continue;
				}
				scripts[sl] = true;
				f.writefln("\t\"%s\" -> \"%s\"", bname, sl);
				count++;
			}
			if (count > 1) multiple_script[bname] = true;
		} catch (Exception e) {
			f.writefln("ERROR2: %s at %s", e.toString, file);
			throw(e);
		}
		//break;
	});
	
	char[][][char[]] subgraphs;
	
	foreach (s; scripts.keys) {
		char si = s[0];
	
		switch (s) {
			case "MAINMENU", "NOTICE": si = '-'; break;
			default: break;
		}
		
		f.writef("\t\"%s\" [", s);

		version (graph_clean) {
			char[] color = "FFFFFF", fontcolor = "000000";

			switch (si) {
				case 'A': color = "FF7F7F"; subgraphs["A"] ~= s; break;
				case 'N': color = "7FFF7F"; subgraphs["N"] ~= s; break;
				case 'M': color = "7F7FFF"; subgraphs["M"] ~= s; break;
				case 'T': color = "A0A0A0"; break;
				default : color = "A0A03F"; break;
			}
			
			// http://www.graphviz.org/doc/info/shapes.html
			if (s in end_script) {
				f.writef("shape=parallelogram,fontsize=15,weight=2.0");
				fontcolor = "FFFFFF";
			} else if (s in multiple_script) {
				f.writef("shape=diamond,fontsize=13");
				fontcolor = "FFFFFF";
			} else {
				f.writef("shape=ellipse");
			}
		
			f.writef(",color=\"#%s\",fontcolor=\"#%s\"", color, fontcolor);
		}
		
		f.writefln("];");
	}
	
	if (false)
	{
		foreach (char[] sg_name, sg; subgraphs) {
			f.writefln("\tsubgraph %s {", sg_name);
			f.writefln("\t\trank = same;");
			foreach (s; sg) {
				f.writefln("\t\t\"%s\";", s);
			}
			f.writefln("\t}");
		}
	}

	f.writefln("}");
	f.close();
	
	system("dot.exe -Tpng graph.dot -o graph.png");
	system("graph.png");
}

void help() {
	writefln("Yume Miru Kusuri - utilidades - soywiz 2008");
	writefln("action <op>");
	writefln();
	writefln("   r  - reinsertar script de acme");
	writefln("   e  - extraer el script a la carpeta WS");
	writefln("   e2 - extraer el script a la carpeta WS.SPA");
	writefln("   e3 - extraer el script a la carpeta WS11");
	writefln("   ea - extraer fichero arc <fichero>");
	writefln("   x  - traducir el ejecutable");
	writefln("   g  - generar gragico");
	writefln("   d  - descomprime y pasa a tga un wip");
}

void backup(char[] ori, char[] back) {
	if (!std.file.exists(back)) copy(ori, back);
}

void com.talestra.criminalgirls.main(char[][] args) {
	// Hacemos una copia de seguridad del script si no existe previamente
	backup("Rio.arc", "Rio.en.arc");
	backup("yumemiru.exe", "yumemiru.en.exe");

	if (args.length < 2) {
		help();
		return;
	}
	
	switch (tolower(args[1])) {
		case "r": Script.processACME(); break;
		case "e" : script_decompile_all("WS", "Rio.en.arc"); break;
		case "e2": script_decompile_all("WS.SPA", "Rio.arc"); break;
		case "e3": script_decompile_all("WS11", "Rio.en11.arc"); break;
		case "x":
			auto s = new File("yumemiru.exe", FileMode.Out | FileMode.In);
			auto sw = new SliceStream(s, 0x793C8, 0x793C8 + 0x30);
			sw.writeString("YUME MIRU KUSURI :: Una droga que te har\xE1 so\xF1ar\0");
			s.close();
		break;
		case "g":
			graph_gen();
		break;
		case "ea":
			if (args.length >= 3) {
				extract_arc(args[2]);
			} else {
				writefln("Hay que especificar el fichero");
			}
		break;
		case "d":
			if (args.length >= 3) {
				foreach (k, i; decompressWIP(args[2])) {
					char[] name = args[2] ~ std.string.format(".%d.tga", k);
					writefln("%s", name);
					i.saveTGA(name);
				}
			} else {
				writefln("Hay que especificar el fichero");
			}
		break;
		default:
			help();
		break;
	}
}