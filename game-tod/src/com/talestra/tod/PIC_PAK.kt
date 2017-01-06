package com.talestra.tod

/*
class PIC_PAK {
	ubyte[][] files;

	fun read(fileName: String) {
		val data = cast(ubyte[])std.file.read(fileName);
		val count = *cast(uint *)data.ptr;
		uint[] positions;
		//writefln("%d", data.length);
		for (int n = 0; n < count; n++) {
			positions ~= *cast(uint *)(data.ptr + 4 + 4 * n);
		}
		positions ~= data.length;
		files = [];
		for (n in 0 until count) {
			val start = positions[n + 0];
			val end   = positions[n + 1];
			files ~= data[start..end];
		}
	}

	fun write(fileName: String) {
		val file = BufferedFile(fileName, FileMode.OutNew);
		{
			uint offset = 4 + 4 * files.length;
			file.write(cast(uint)files.length);
			foreach (cfile; files) {
			file.write(offset);
			offset += cfile.length;
		}
			foreach (cfile; files) file.write(cfile);
		}
		file.close();
	}

	fun extract(folder: String) {
		try { std.file.mkdir(folder); } catch { }
		foreach (n, file; files) {
			std.file.write(folder ~ std.string.format("/%03d.TIM", n), file);
		}
	}
}

fun prepare_pic(tempDir: String) {
	val za = ZipArchive(cast(ubyte[])import("PIC.ZIP"));
	for (e in za.directory) za.expand(e);
	//writefln("%s", za.directory["BF.TIM"].expandedData);
	std.file.write(tempDir ~ "/BF_SPA.D", compressWithHeader(za.directory["BF.TIM"].expandedData, 3));
	// FACE
	{
		val pak = PIC_PAK()
		std.file.write("$tempDir/MC.U", decompressWithHeader(cast(ubyte[])std.file.read(tempDir ~ "/MC.D")));
		pak.read("$tempDir/MC.U");
		//pak.extract("temp/MC.ORI");
		pak.files[10] = za.directory["MC/010.TIM"].expandedData;
		pak.files[14] = za.directory["MC/014.TIM"].expandedData;
		pak.write("$tempDir/MC_SPA.U");
		std.file.write("$tempDir/MC_SPA.D", compressWithHeader(cast(ubyte[])std.file.read(tempDir ~ "/MC_SPA.U"), 3));
	}
}
*/

/*
unittest {
	try { std.file.mkdir("temp"); } catch { }
	prepare_pic("temp");

	//std.file.write("demo.c3", compressWithHeader(cast(ubyte[])import("BF.TIM"), 3));
	//writefln("yupii");
}
*/
