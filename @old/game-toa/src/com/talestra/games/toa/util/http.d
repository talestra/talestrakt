module http;

import std.string, std.conv, std.stream, std.regexp;
import std.socket, std.socketstream;
import std.stdio, std.c.stdlib;

uint getdhvalue(char[] s) {
	uint r = 0, d, l = s.length;
	for (int n = 0; n < l; n++) {
		char c = s[n];
		if (c >= '0' && c <= '9') d = c - '0';
		else if (c >= 'a' && c <= 'f') d = c - 'a' + 0x0a;
		else if (c >= 'A' && c <= 'F') d = c - 'A' + 0x0a;
		else { d = 0; throw(new Exception("Digito invalido (" ~ c ~ ")")); }
		r |= d; r <<= 4;
	} r >>= 4;

	return r;
}

class TcpSocketTimeout : Socket {
	this(Address connectTo) {
		super(connectTo.addressFamily(), SocketType.STREAM, ProtocolType.TCP);
		connect(connectTo);
	}
}

class HTTP {
	static ubyte[] GET(char[] url) {
		int i;

		writefln("Downloading... '%s'", url);

		if ((i = std.string.find(url, "://")) != -1) {
			if (icmp(url[0 .. i], "http")) throw new Exception("http:// expected");
			url = url[i + 3 .. url.length];
		}

		if ((i = std.string.find(url, '#')) != -1) url = url[0 .. i];

		char[] domain;
		if((i = std.string.find(url, '/')) == -1) {
			domain = url;
			url = "/";
		} else {
			domain = url[0 .. i];
			url = url[i .. url.length];
		}

		uint port = 80;
		if ((i = std.string.find(domain, ':')) == -1) {
			port = 80;
		} else {
			port = std.conv.toUshort(domain[i + 1 .. domain.length]);
			domain = domain[0 .. i];
		}

		auto Socket sock = new TcpSocketTimeout(new InternetAddress(domain, port));
		Stream ss = new SocketStream(sock);
		//ss.block = false;

		if (port != 80) domain = domain ~ ":" ~ std.string.toString(port);

		ss.writeString(
			"GET " ~ url ~ " HTTP/1.1\r\n"
			"Host: " ~ domain ~ "\r\n"
			"Connection: close\r\n"
		"\r\n");

		// Skip HTTP header.
		char[] line;

		bool chunked = false;

		line = ss.readLine();

		auto reg = new RegExp("HTTP/1.1[ ]+([0-9]+)");
		if (reg.test(line)) {
			uint resp = std.conv.toUint(reg.match(line)[1]);
			switch ((resp / 100)) {
				case 2: break;
				case 3: case 5: case 4:
					throw(new Exception("ERROR: " ~ line));
					return [];
				break;
			}
		}

		uint datalength = 0;

		for(;;) {
			line = ss.readLine();
			if (!line.length) break;
			char[] param, value;

			if ((i = std.string.find(line, ":")) != -1) {
				param = tolower(strip(line[0..i]));
				value = strip(line[i+1..line.length]);

				if (param == "transfer-encoding" && value == "chunked") chunked = true;
				if (param == "content-length") datalength = std.conv.toUint(value);
			}
		}

		char[] ret;

		if (chunked) {
			while (!ss.eof) {
				char[] buffer;
				uint toread = getdhvalue(ss.readLine());
				if (toread == 0) continue;

				buffer.length = toread;
				ss.readExact(buffer.ptr, 1);

				ss.readExact(buffer.ptr, toread);
				ret ~= buffer;
			}
		} else {
			if (datalength > 0) {
				char[] buffer;
				buffer.length = datalength;
				ss.readExact(buffer.ptr, 1);
				ss.readExact(buffer.ptr, datalength);
				ret ~= buffer;
			} else {
				ubyte[1024] buffer;
				ss.readExact(buffer.ptr, 1);
				while (!ss.eof()) {
					ss.read(buffer);
					ret ~= cast(char[])buffer;
				}
			}
		}

		return cast(ubyte[])ret;
	}
}
