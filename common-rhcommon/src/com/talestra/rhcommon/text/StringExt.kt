package com.talestra.rhcommon.text

fun explode(separator: String, subject: String, max: Int = Int.MAX_VALUE): List<String> = TODO()

fun String.escape(): String {
	var out = ""
	for (c in this) {
		when (c) {
			'\n' -> out += "\\n"
			'\r' -> out += "\\r"
			'\t' -> out += "\\t"
			'"' -> out += "\\\""
			'\'' -> out += "\\'"
			'\\' -> out += "\\\\"
			else -> out += c
		}
	}
	return out
}

fun String.unescape(): String {
	var out = ""
	var n = 0
	while (n < this.length) {
		val c = this[n++]
		if (c == '\\') {
			val c2 = this[n++]
			when (c2) {
				'n' -> out += "\n"
				'r' -> out += "\r"
				't' -> out += "\t"
				'"' -> out += "\""
				'\'' -> out += "\'"
				'\\' -> out += "\\"
				else -> out += "$c$c2"
			}
		} else {
			out += c
		}
	}
	return out
}

fun String.quote(): String = "\"" + this.escape() + "\""
fun String.unquote(): String {
	if (this.length >= 2) {
		val cc = this[0]
		if (this.startsWith(cc) && this.endsWith(cc)) {
			return this.substring(1, this.length - 1).unescape()
		}
	}
	throw IllegalArgumentException("Not a quoted string")
}