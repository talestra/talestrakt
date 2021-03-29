import imports;

ubyte[] BTSCT_encode(char[][] e) {
	ubyte[] title = StringEncoder.encode(e[0]), text = StringEncoder.encode(e[1]);
	title.length = 0x20;
	text.length = 0x100;
	return title ~ text;
}

char[][][uint] getBTSC(char[] s) {
	char[][][uint] r;
	s = replace(s, "\r", "");
	foreach (token; s.split2("##")) {
		int pos;
		if ((pos = std.string.find(token, "\n")) != -1) {
			int k = intFromBase(strip(token[2..pos]), 16);
			r[k] = split2(strip(token[pos..token.length]), "\n", 2);
		}
	}
	return r;
}