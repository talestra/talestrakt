package com.talestra.rhcommon.lang

inline fun <T> mapWhile(cond: () -> Boolean, map: () -> T): List<T> {
	val out = arrayListOf<T>()
	while (cond()) out += map()
	return out
}
