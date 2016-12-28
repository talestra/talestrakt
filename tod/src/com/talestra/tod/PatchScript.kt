package com.talestra.tod

/*
fun PatchScript(fName: String, tName: String, translationStream: Stream2) {
	val pak_ori = PAK(BufferedFile("$fName.B", FileMode.In    ), new BufferedFile(fName ~ ".DAT", FileMode.In    ), true );
	val pak_new = PAK(BufferedFile("$fName.B", FileMode.OutNew), new BufferedFile(tName ~ ".DAT", FileMode.OutNew), false);
	val translation = new Translation;
	translation.load(translationStream);

	int[int] translate_rooms;
	foreach (line; std.string.split(import("list.txt"), "\n")) {
		auto matches = search(line, r"(\d+)...([\w\s]+)(\((\d+)\))?");
		if (matches !is null) {
			int from = std.conv.toInt(matches.match(1));
			switch (matches.match(2)) {
				case "Repeated ": {
				//writefln("TO:%s", matches.match(3)[1..$ - 1]);
				int to   = std.conv.toInt(matches.match(4));
				translate_rooms[from] = to;
			} break;
				default:
				translate_rooms[from] = from;
				break;
			}
			//writefln("%s", matches.match(0));
			//writefln("%s", line);
		}
	}

	for (room_to_update in 0 until 1315) {
		val room_base = translate_rooms[room_to_update];

		//localProgress.set(room_to_update, 1315);
		//writefln("%d <- %d", room_to_update, room_base);

		val room = SELFPAK(pak_ori.extractFile(room_to_update));
		if ((room_base in translation.texts) && (room.length >= 2)) {
			auto scriptDecompressed = Compression.Decompress(room[room.length - 1]);
			auto script = new ScriptFile(scriptDecompressed);
			script.texts = translation.texts[room_base];
			room[room.length - 1] = Compression.Compress(script.stream);
		} else {
			if (room_to_update >= 1 && room_to_update <= 9) {
				auto images_worldmap = SELFPAK(Compression.Decompress(room[0]));
				images_worldmap[10] = new MemoryStream(cast(ubyte[])import("MDAT_WM_0010.tim"));
				room[0] = Compression.Compress(images_worldmap.stream);
				//writefln("   Map");
			} else {
				//writefln("   Not in list");
			}
		}

		pak_new.addFile(room.stream);
	}
	pak_new.close();
	pak_ori.close();
}
*/

/*unittest {
	//PatchScript("temp/M", "temp/M_SPA", new BufferedFile("res/script.bin"));
	/*
	writefln("Testing ScriptFile");
	auto tr = new Translation;
	tr.load(new BufferedFile("res/script.bin"));
	*/

	//PatchScript("temp/M", "temp/M_SPA");

	/*
	auto pak = new PAK(new BufferedFile("temp/M.B"), new BufferedFile("temp/M.DAT"));
	auto fo = new File("temp/test_script.bin", FileMode.Out);
	auto script = new ScriptFile(pak.extractFileScriptUncompress(0));
	script.texts = tr.texts[0];
	script.write(fo);
	*/
	//fo.copyFrom();
}*/
