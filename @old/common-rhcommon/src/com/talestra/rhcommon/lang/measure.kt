package com.talestra.rhcommon.lang

inline fun <T> measure(name: String, callback: () -> T): T {
	val start = System.nanoTime()
	val result = callback()
	val end = System.nanoTime()
	println("$name...${(end - start).toDouble() / 1_000_000.0}")
	return result
}