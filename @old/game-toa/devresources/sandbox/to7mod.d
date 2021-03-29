import std.stdio, std.file, std.string, std.stream;


int main() {
	char[] path = "TO7MAP_MOD";
	listdir(
		path,
		delegate bool(char[] name) {
			// 50 KB
			ubyte data[10240 * 5];
			char[] rname = std.string.format("%s\\%s", path, name);
			File f = new File(rname, FileMode.Append);
			writefln("%s: %d", rname, f.position);			
			//f.write(data);
			f.close();
			return true;
		}
	);
	
	return 0;
}

// 1777088
