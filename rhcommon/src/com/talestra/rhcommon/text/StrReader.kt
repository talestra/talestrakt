package com.talestra.rhcommon.text

class StrReader(val str: String, var offset: Int = 0) {
	val length: Int get() = str.length
	val eof: Boolean get() = offset >= length
	fun peek(): Char = str[offset]
	fun read(): Char = str[offset++]

	inline fun readWhile(cond: (c: Char) -> Boolean): String {
		val start = offset
		while (cond(peek())) read()
		return str.substring(start, offset)
	}

	fun expect(c: Char) {
		val r = read()
		if (r != c) throw IllegalArgumentException("Expected '$c' but found'$r'")
	}

	fun readQuotedString(): String {
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

	fun clone() = StrReader(str, offset)
}
