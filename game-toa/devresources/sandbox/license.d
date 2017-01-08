import std.stdio, std.file, std.string, std.stream;

int main() {
	ubyte data[0x8000];
	File f = new File("ABYSS.ISO", FileMode.Out | FileMode.In);
	File fr = new File("ABYSS-ORIGINAL.ISO", FileMode.In);
	
	fr.read(data);	
	f.write(data);
	
	f.close();
	fr.close();
	
	return 0;
}

// 1777088
