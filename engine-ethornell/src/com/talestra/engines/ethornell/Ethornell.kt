package com.talestra.engines.ethornell

// Version of the utility.
const val _version = "0.3";

// Utility macros.
fun max(a: Int, b: Int): Int {
	return if (a > b) a else b
}

fun min(a: Int, b: Int): Int {
	return if (a < b) a else b
}

fun HIWORD(v: Int): Int {
	return (v ushr 16) and 0xFFFF
}

fun LOWORD(v: Int): Int {
	return v and 0xFFFF
}

fun HIBYTE(v: Int): Int {
	return (v ushr 8) and 0xFF
}

fun LOBYTE(v: Int): Int {
	return v and 0xFF
}

class Hash {
	var hash_val: Int = 0
	// Utility function for the decrypting.
	fun hash_update(): Int {
		val edx = (20021 * LOWORD(hash_val));
		val eax = (20021 * HIWORD(hash_val)) + (346 * hash_val) + HIWORD(edx);
		hash_val = (LOWORD(eax) shl 16) + LOWORD(edx) + 1;
		return eax and 0x7FFF;
	}
}
