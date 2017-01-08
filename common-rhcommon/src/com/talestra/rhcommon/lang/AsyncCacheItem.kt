package com.talestra.rhcommon.lang

import com.soywiz.korio.async.Promise
import com.soywiz.korio.async.asyncFun
import kotlin.coroutines.startCoroutine

class AsyncCacheItem<T>(private val gen: suspend () -> T) {
	var started = false
	val deferred = Promise.Deferred<T>()

	suspend fun get() = asyncFun {
		if (!started) {
			started = true
			gen.startCoroutine(deferred.toContinuation())
		}
		deferred.promise.await()
	}
}
