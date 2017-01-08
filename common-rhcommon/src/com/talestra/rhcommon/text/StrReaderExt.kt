package com.talestra.rhcommon.text

import com.soywiz.korio.util.StrReader

fun StrReader.readQuotedString(): String {
	var out = ""
	expect('"')
	while (true) {
		val c = read()
		if (c == '"') break
		if (c == '\\') {
			val c2 = read()
			when (c2) {
				'n' -> out += '\n'
				'r' -> out += '\r'
				't' -> out += '\t'
				'"' -> out += '\"'
				'\'' -> out += '\''
				else -> out += c2
			}
		} else {
			out += c
		}
	}
	return out
}