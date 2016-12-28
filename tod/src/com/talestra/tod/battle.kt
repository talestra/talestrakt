package com.talestra.tod

//fun patchBattle() {
//	val PTR_START = 0xF3C00
//	val PTR_LEN = 0x153
//
//	val pointer_stream = SliceStream(BufferedFile("$tempDir/SLUS_006.26"), PTR_START, PTR_START + PTR_LEN * 8)
//	val data_stream = BufferedFile("$tempDir/B.DAT")
//	scope(exit) data_stream . close ();
//	val pointer_stream_write = new SliceStream (new File (tempDir ~ "/SLES_106.26", FileMode.In | FileMode.Out), PTR_START, PTR_START+PTR_LEN * 8);
//	//auto pointer_stream_write = new MemoryStream;
//
//	val pak = PAK(pointer_stream, data_stream, true);
//
//	char[][char[]] translate;
//
//	for (stream in listOf(MemoryStream(import("enemy_names.txt")), MemoryStream(import("enemy_skills.txt")))) {
//		foreach(char[] name; stream) {
//		char[][] slices = std . string . split (name, ":");
//		translate[slices[0].dup] = slices[1].dup;
//	}
//	}
//	//writefln("%s", translate);
//
//	fun textPart(data: ByteArray): ByteArray {
//		//writefln("%s", data);
//		for (n in 0 until data.size) {
//			val m = data.size - n - 1
//			val c = data[m].toU8()
//			if (c != 0x00 && c != 0x20) return data.sliceArray(0 until m)
//			//writefln("%d:'%s'", k, cast(char)c);
//		}
//		return byteArrayOf();
//	}
//
//	val b_new = File("$tempDir/B_SPA.DAT", FileMode.OutNew);
//
//	pointer_stream_write.position = 0;
//
//	fun addStream (stream: Stream2, _align: Int = 0x800) {
//		while (b_new.position % _align) b_new.position = b_new.position + 1;
//		pointer_stream_write.write(cast(uint) b_new . position);
//		pointer_stream_write.write(cast(uint) stream . size);
//		b_new.copyFrom(stream);
//	}
//
//	for (n in 0 until pak.length) {
//		if (n == 53) {
//			val selfpak = SELFPAK_NoCount (pak[n]);
//			//std.file.write(r"C:\projects\talestra\tod\patcher\53.bin", cast(ubyte[])pak[n].readString(pak[n].size));
//			val uncompressed = Compression.Decompress(selfpak[0])
//			uncompressed.position = 0
//
//			uncompressed = new MemoryStream (cast(ubyte[]) import ("53_0.bin"));
//
//			//auto uncompressed = selfpak[21];
//			//std.file.write(r"C:\projects\talestra\tod\patcher\53_0.bin", cast(ubyte[])uncompressed.readString(uncompressed.size));
//			uncompressed.position = 0; selfpak[0] = Compression.Compress(uncompressed);
//			addStream(selfpak.stream);
//			continue;
//		}
//
//		if (n >= 91 && n <= 280) {
//			val selfpak = new SELFPAK_NoCount (pak[n]);
//			val uncompressed = Compression.Decompress(selfpak[7]); uncompressed.position = 0;
//			val enemy_name = ByteArray(0x10)
//			val skill_name = ByteArray(0x14)
//			uncompressed.position = 0;
//			uncompressed.read(enemy_name);
//			char[] enemy_name_char = textPart (enemy_name);
//			if (enemy_name_char in translate) {
//				//printf("%d:'%s'\n", n, toStringz(enemy_name_char));
//				enemy_name_char = translate[enemy_name_char];
//				enemy_name[] = 0x20;
//				enemy_name[0..enemy_name_char.length] = cast(ubyte[]) enemy_name_char;
//				uncompressed.position = 0;
//				uncompressed.write(enemy_name);
//			} else {
//				printf("UNTRANSLATED!! '%s'\n", toStringz(enemy_name_char));
//			}
//
//			for (m in 0 until 8) {
//				val cposition = 0xC8+(0x40+skill_name.size) * m;
//				uncompressed.position = cposition;
//				uncompressed.read(skill_name);
//				val skill_name_char = textPart(skill_name)
//				if (skill_name_char.size > 0) {
//					if (skill_name_char in translate) {
//						skill_name_char = translate[skill_name_char];
//						//printf("'%s'\n", toStringz(enemy_name_char));
//						skill_name[] = 0x20;
//						//writefln("%d", skill_name_char.length);
//						skill_name[0..skill_name_char.length] = cast(ubyte[]) skill_name_char;
//						skill_name[skill_name_char.length] = 0x00;
//						uncompressed.position = cposition;
//						uncompressed.write(skill_name);
//					} else {
//						printf("UNTRANSLATED!! '%s'\n", toStringz(skill_name_char));
//					}
//				}
//			}
//			uncompressed.position = 0; selfpak[7] = Compression.Compress(uncompressed);
//			addStream(selfpak.stream);
//
//			continue;
//		}
//
//		addStream(pak[n]);
//	}
//
//	//b_new.truncate(0x418800);
//
//	while (b_new.position % 0x800) b_new.write(cast(ubyte)0);
//
//	b_new.close();
//	pointer_stream_write.close();
//
//	//SetEndOfFile();
//
//	//truncate(toStringz(tempDir ~ "/B_SPA.DAT"), 0x418800);
//
//	//foreach (n, e; pak) writefln("%d %d", n, e.size);
//}