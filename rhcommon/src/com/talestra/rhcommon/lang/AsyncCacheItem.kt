package com.talestra.rhcommon.lang

import com.soywiz.korio.async.ContinuationWait
import com.soywiz.korio.async.asyncFun
import kotlin.coroutines.startCoroutine

class AsyncCacheItem<T>(private val gen: suspend () -> T) {
	var started = false
	val cc = ContinuationWait<T>()

	suspend fun get() = asyncFun {
		if (!started) {
			started = true
			gen.startCoroutine(cc.continuation)
		}
		cc.await()
	}
}
