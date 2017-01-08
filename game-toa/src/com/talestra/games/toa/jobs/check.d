import imports;

import dfl.all;

import movie;

Form form;

void questionEnd(char[] text) {
	if (msgBox(form, text, "Atención", MsgBoxButtons.OK_CANCEL, MsgBoxIcon.EXCLAMATION, MsgBoxDefaultButton.BUTTON2) == DialogResult.CANCEL) {
		throw(new Exception(""));
	}
}

void questionEndFatal(char[] text) {
	msgBox(form, text, "Error", MsgBoxButtons.OK, MsgBoxIcon.EXCLAMATION, MsgBoxDefaultButton.BUTTON2);
	throw(new Exception(""));
}

bool isJAP() {
	return FS.gin.exists("SLPS_255.86");
}

bool isGAME() {
	return FS.gin.exists("SLUS_213.86");
}

bool isUNDUB() {
	return (FS.gin["TO7EV.CVM"].size > 800000000);
}

void process(Form form = null) {
	.form = form;

	if (isJAP) throw(new Exception("Versión no soportada: Se ha detectado que ha especificado la ISO de la versión japonesa del 'Tales of the Abyss' (no soportada por nuestro parcheador). Este parcheador solo acepta la versión americana (USA)"));
	if (!isGAME) throw(new Exception("La ISO especificada no es la versión USA de 'Tales of the Abyss'"));
	
	if (isUNDUB) {
		questionEnd("Versión UNDUB detectada. No hemos probado esta versión extensivamente, así que no podemos garantizar que funcione correctamente de principio a fin. La primera versión de la UNDUB no tiene voces en las skits. Y aún la segunda versión tiene algunas skits desincronizadas. ¿Deseas continuar con el proceso de parcheo igualmente?");
		if (!std.file.exists("toa-spa-movies-undub.pak")) {
			questionEndFatal("No se ha encontrado el fichero 'toa-spa-movies-undub.pak'. Este fichero es obligatorio. Se puede descargar de http://toa.tales-tra.com/ y de http://tracker.tales-tra.com/ : 'Pack de vídeos en castellano para Tales of the Abyss (para la UNDUB)'");
		}
	} else {
		if (!std.file.exists("toa-spa-movies.pak")) {
			questionEndFatal("No se ha encontrado el fichero 'toa-spa-movies.pak. Este fichero es obligatorio. Se puede descargar de http://toa.tales-tra.com/ y de http://tracker.tales-tra.com/ : 'Pack de vídeos en castellano para Tales of the Abyss'");
		}
	}

	ubyte[][][char[]] check_hashes;
	
	check_hashes["SLUS_213.86"]               = [cast(ubyte[])x"5687edaa1da9492b3d64f8f44838c63b", cast(ubyte[])x"673b09c5e28e9b7a454c81391b1dcedf"];
	check_hashes["root/OV_PDVD_BTL_US.OVL"]   = [cast(ubyte[])x"8e453175a88e7c075432e6a9a6d249dc"];
	check_hashes["root/OV_PDVD_FIELD_US.OVL"] = [cast(ubyte[])x"ef374ee306d6f29e0f4f14257b8c370a"];
	check_hashes["root/OV_PDVD_SFD_US.OVL"]   = [cast(ubyte[])x"42ddd78d8eb386d37e6a1f25668c28da"];
	check_hashes["root/OV_PDVD_SKIT_US.OVL"]  = [cast(ubyte[])x"5bcf3ec462951a04316e39759a8c285b"];
	
	char[] errors;
	
	foreach (name, hashes; check_hashes) {
		writef("Comprobando HASH: '%s'...", name);
		ubyte[] fhash = tocommon.md5(FS.gin[name].open);
		bool ok = false;
		foreach (hash; hashes) {
			if (fhash == hash) {
				ok = true;
				break;
			}
		}
		
		if (!ok) {
			writefln("Error!");
			errors ~= std.string.format("\n'%s'. Esperado:'%s'. Obtenido:'%s'.", name, hexdump(hashes[0]), hexdump(fhash));
		} else {
			writefln("OK");
		}
		
		FS.gin[name].close();
	}

	if (errors.length) throw(new Exception("Fallo de comprobación de md5 en los siguientes ficheros:" ~ errors));

	/*
	if (!FS.movie.exists) questionEnd("No se ha encontrado la carpeta 'movie'. Sin esta carpeta no se subtitularán los videos del TotA.");
	
	foreach (e; movie.list) {
		if (!FS.movie.exists(e)) {
			questionEnd(format("No se ha encontrado el fichero 'movie/%s'. El video no se subtitulará.", e));
		}
	}
	*/
}

void process2() {
	if (FS.gin.size != FS.gout.size) {
		questionEndFatal("Las isos de entrada y salida tienen longitudes diferentes.");
	}
}