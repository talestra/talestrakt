module iml2iso;

import std.stdio, std.file, std.string, std.stream;

class FileMap {
	class Section {
		int start;
		int end;
		Stream from;	
	}
	
	Section[] sections;
	
	void writeTo(Stream to) {
		ubyte sector[0x800];
		foreach (section; sections) {
			int todump = section.end - section.start + 1;
			to.position = section.start * 0x800;
			while (todump--) {
				section.from.read(sector);
				to.write(sector);
			}
		}
	}
}

int main() {		
	return 0;
}

// 1777088
