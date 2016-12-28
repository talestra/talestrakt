module ppf;

import std.stream, std.stdio;

void ppfPatch(Stream ppf, Stream output) {
	ppf.position = 0;
	assert(ppf.readString(5) == "PPF20");
	ppf.position = 1084;
	while (!ppf.eof) {
		uint chunkOffset;
		ubyte chunkLen;
		ubyte[] chunkData;

		// Read PPF info.
		ppf.read(chunkOffset);
		ppf.read(chunkLen); chunkData.length = chunkLen;
		ppf.read(chunkData);

		// Write.
		output.position = chunkOffset;
		output.write(chunkData);
	}
}

/+unittest {
	auto fileOriginal      = "res/SLUS_006.26.bak";
	auto filePatchedNormal = "res/SLUS_006.26";
	auto filePatchedPPF    = "temp/SLUS_006.26.patchedppf";
	auto filePPF           = "res/SLUS_006.26.ppf";

	try { std.file.mkdir("temp"); } catch { }
	std.file.copy(fileOriginal, filePatchedPPF);
	{
		scope ppf  = new BufferedFile(filePPF);
		scope temp = new File(filePatchedPPF, FileMode.Out | FileMode.In);
		ppfPatch(ppf, temp);
	}
	writefln("**** testing ppf");
	//assert(std.file.read(filePatchedPPF) == std.file.read(filePatchedNormal));
	std.file.remove(filePatchedPPF);
}+/