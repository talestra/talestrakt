import imports;

import check;

void process_dat(bool alone = false) { scope(exit)Progress.pop;Progress.push("Traduciendo ficheros dat");
	int count = 0, cpos = 0;
	
	foreach (c; FS.patch["dat"]) if (c.isFile) count++;

	foreach (c; FS.patch["dat"]) {
		bool limit = true;
		if (!c.isFile) continue;
		//writefln(c.name);
		Progress.set(cpos++, count, c.name);
		//if (c.name == "_SLTSKL_.DAT") limit = false;
		//if (c.name == "_ACS_.DAT") limit = false;
		try {
			//FS.gout["root/" ~ c.name].replace(c.open, limit);
			c.saveto(FS.temp["root/" ~ c.name]);
			if (alone) {
				writefln("misc.dat.alone.replace: %s", c.name);
				FS.gout["root/" ~ c.name].replace(c);
			}
		} catch (Exception e) {
			writefln("\nmisc.error: '%s'\n", e.toString);
		}
	}
	
	//FS.gout["root/_CLBD.DAT"].makePPF(FS.temp["_CLBD.DAT.ppf"].open(FileMode.OutNew), 0);
}

void process_images(bool alone = false) { scope(exit)Progress.pop;Progress.push("Traduciendo imágenes");
	foreach (c; FS.patch["images/root"]) {
		bool limit = true;
		if (!c.isFile) continue;
		//writefln(c.name);
		try {
			//FS.gout["root/" ~ c.name].replace(c.open, limit);
			c.saveto(FS.temp["root/" ~ c.name]);
			if (alone) FS.gout["root/" ~ c.name].replace(c);
		} catch (Exception e) {
			writefln("misc.error: '%s'", e.toString);
		}
	}
	
	bool undub = check.isUNDUB;
	bool special_etc;
	
	if (undub) {
		writefln("misc.warning.undub: las imágenes de los minijuegos de la undub, son los de la versión japonesa y no coinciden. Además faltan los ficheros PK_NOTIP.TM2 y S_DB_SECRET.TM2. Si da problemas, es cosas de la undub. Si salen cosas en japonés, es cosa de la undub también.");	
	}
	
	if (FS.gin["ev/PK_ETC.TM2"].size != 1984512) {
		special_etc = true;
		writefln("misc.warning.undub: la imagen PK_ETC.TM2 no tiene el tamaño original. Se usará una versión modificada.");
	}
	
	
	foreach (c; FS.patch["images/ev"]) {
		if (!c.isFile) continue;
		//writefln(c.name);
		
		if (special_etc && c.name == "PK_ETC.TM2") continue;
		
		try {
			FS.gout["ev/" ~ c.name].replace(c.open, true);
		} catch (Exception e) {
			writefln("misc.error: '%s'", e.toString);
		}
	}
	
	if (special_etc) {
		foreach (c; FS.patch["images/ev.undub"]) {
			try {
				FS.gout["ev/" ~ c.name].replace(c.open, true);
			} catch (Exception e) {
				writefln("misc.error.undub: '%s'", e.toString);
			}
		}
	}
}

void process_ending(bool alone = false) { scope(exit)Progress.pop;Progress.push("Traduciendo ending");
	FS.patch["end/TOAEND_ES.TXT"].saveto(FS.temp["root/TOAEND_US.TXT"]);
	//FS.gout["root/TOAEND_JP.TXT"].replace(FS.patch["end/TOAEND_ES.TXT"].open, false);
	//FS.gout["root/TOAEND_JP.TXT"].replace(FS.patch["end/TOAEND_US.TXT"].open, false);
}

void process(bool alone = false) { scope(exit)Progress.pop;Progress.push("Opciones misc");
	process_dat(alone);
	process_images(alone);
	process_ending(alone);
}

void regen_root_do() { scope(exit)Progress.pop;Progress.push("Actualizando CVM");
	//version (make_only_title) return;
	FS.gout["root"].regen(FS.temp["root"], delegate int(char[] name, int pos_cur, int pos_len, long pos, long total, bool error) {
		if (error) {
			printf("\nregen [%-16s] ", toStringz(name));
			printf("error\n\n");
		} else {
			/*
			printf("(%3.2f/%.2f)\r",
				cast(float)((cast(real)pos) / 1024 / 1024),
				cast(float)((cast(real)total) / 1024 / 1024)
			);
			*/
		}
		Progress.set(pos_cur, pos_len, name);
		return false;
	});
}

void regen_copy_extra() { scope(exit)Progress.pop;Progress.push("Copiando archivos extra");
	int count = 0;
	foreach (f; FS.gin["root"]) { patch_stopPoint();
		auto ff = FS.temp["root/" ~ f.name];
		if (ff.exists) continue;
		Progress.set(count++, 209, f.name);
		ff.copyFrom(f);
	}
	FS.temp["root/SKIT001.DAT"].open(FileMode.OutNew).close();
}

void regen_root() { scope(exit)Progress.pop;Progress.push("Regenerando CVM de root en iso");
	regen_copy_extra();
	regen_root_do();
	
}