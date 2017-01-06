package com.talestra.dividead

import com.jtransc.io.ra.RAStream
import java.io.ByteArrayOutputStream

fun RAStream.readStringz(count: Int): String {
	return this.readBytes(count.toLong()).toString(Charsets.UTF_8).trimEnd('\u0000');
}

fun RAStream.readStringz(): String {
	val out = ByteArrayOutputStream()
	while (true) {
		val c = readU8_LE()
		if (c == 0) break
		out.write(c.toInt())
	}
	return out.toByteArray().toString(Charsets.UTF_8)
}