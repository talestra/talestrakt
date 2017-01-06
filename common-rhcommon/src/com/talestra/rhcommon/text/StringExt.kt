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
			else -> out += c
		}
	}
	return out
}

