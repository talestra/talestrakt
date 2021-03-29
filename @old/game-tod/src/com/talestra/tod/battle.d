import std.file, std.stream, std.string, std.stdio, std.regexp;
import common, utils, lzsimple;

void patchBattle() {
	const uint PTR_START = 0xF3C00;
	const uint PTR_LEN   = 0x153;
	
	auto pointer_stream = new SliceStream(new BufferedFile(tempDir ~ "/SLUS_006.26"), PTR_START, PTR_START + PTR_LEN * 8);
	scope data_stream   = new BufferedFile(tempDir ~ "/B.DAT");
	scope (exit) data_stream.close();
	auto pointer_stream_write = new SliceStream(new File(tempDir ~ "/SLES_106.26", FileMode.In | FileMode.Out), PTR_START, PTR_START + PTR_LEN * 8);
	//auto pointer_stream_write = new MemoryStream;

	auto pak = new PAK(pointer_stream, data_stream, true);
	
	char[][char[]] translate;

	foreach (stream; [new MemoryStream(import("enemy_names.txt")), new MemoryStream(import("enemy_skills.txt"))]) {
		foreach (char[] name; stream) {
			char[][] slices = std.string.split(name, ":");
			translate[slices[0].dup] = slices[1].dup;
		}
	}
	//writefln("%s", translate);
	
	char[] textPart(ubyte[] data) {
		//writefln("%s", data);
		foreach_reverse (k, c; data)  {
			if (c != 0x00 && c != 0x20) return cast(char[])data[0..k + 1];
			//writefln("%d:'%s'", k, cast(char)c);
		}
		return [];
	}
	
	scope b_new = new File(tempDir ~ "/B_SPA.DAT", FileMode.OutNew);
	
	pointer_stream_write.position = 0;
	
	void addStream(Stream stream, int _align = 0x800) {
		while (b_new.position % _align) b_new.position = b_new.position + 1;
		pointer_stream_write.write(cast(uint)b_new.position);
		pointer_stream_write.write(cast(uint)stream.size);
		b_new.copyFrom(stream);
	}

	for (int n = 0; n < pak.length; n++) {
		if (n == 53) {
			auto selfpak = new SELFPAK_NoCount(pak[n]);
			//std.file.write(r"C:\projects\talestra\tod\patcher\53.bin", cast(ubyte[])pak[n].readString(pak[n].size));
			auto uncompressed = Compression.Decompress(selfpak[0]); uncompressed.position = 0;
			
			uncompressed = new MemoryStream(cast(ubyte[])import("53_0.bin"));
			
			//auto uncompressed = selfpak[21];
			//std.file.write(r"C:\projects\talestra\tod\patcher\53_0.bin", cast(ubyte[])uncompressed.readString(uncompressed.size));
			uncompressed.position = 0; selfpak[0] = Compression.Compress(uncompressed);
			addStream(selfpak.stream);
			continue;
		}
	
		if (n >= 91 && n <= 280) {
			auto selfpak = new SELFPAK_NoCount(pak[n]);
			auto uncompressed = Compression.Decompress(selfpak[7]); uncompressed.position = 0;
			ubyte[0x10] enemy_name;
			ubyte[0x14] skill_name;
			uncompressed.position = 0;
			uncompressed.read(enemy_name);
			char[] enemy_name_char = textPart(enemy_name);
			if (enemy_name_char in translate) {
				//printf("%d:'%s'\n", n, toStringz(enemy_name_char));
				enemy_name_char = translate[enemy_name_char];
				enemy_name[] = 0x20;
				enemy_name[0..enemy_name_char.length] = cast(ubyte[])enemy_name_char;
				uncompressed.position = 0;
				uncompressed.write(enemy_name);
			} else {
				printf("UNTRANSLATED!! '%s'\n", toStringz(enemy_name_char));
			}

			for (int m = 0; m < 8; m++) {
				uint cposition = 0xC8 + (0x40 + skill_name.sizeof) * m;
				uncompressed.position = cposition;
				uncompressed.read(skill_name);
				char[] skill_name_char = textPart(skill_name);
				if (skill_name_char.length) {
					if (skill_name_char in translate) {
						skill_name_char = translate[skill_name_char];
						//printf("'%s'\n", toStringz(enemy_name_char));
						skill_name[] = 0x20;
						//writefln("%d", skill_name_char.length);
						skill_name[0..skill_name_char.length] = cast(ubyte[])skill_name_char;
						skill_name[skill_name_char.length] = 0x00;
						uncompressed.position = cposition;
						uncompressed.write(skill_name);
					} else {
						printf("UNTRANSLATED!! '%s'\n", toStringz(skill_name_char));
					}
				}
			}
			uncompressed.position = 0; selfpak[7] = Compression.Compress(uncompressed);
			addStream(selfpak.stream);
			
			continue;
		}

		addStream(pak[n]);
	}
	
	//b_new.truncate(0x418800);
	
	while (b_new.position % 0x800) b_new.write(cast(ubyte)0);
	
	b_new.close();
	pointer_stream_write.close();
	
	//SetEndOfFile();

	//truncate(toStringz(tempDir ~ "/B_SPA.DAT"), 0x418800);

	//foreach (n, e; pak) writefln("%d %d", n, e.size);
}