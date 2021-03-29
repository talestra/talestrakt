import std.file, std.stream, std.string, std.stdio, std.regexp;
import common, utils;



void write(string fileName, Stream data) {
	scope file = new BufferedFile(fileName, FileMode.OutNew);
	file.copyFrom(data);
	file.close();
}

