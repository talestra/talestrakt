package com.talestra.rhcommon.lang

import com.soywiz.korio.async.Promise
import kotlin.coroutines.startCoroutine

class AsyncCacheItem<T>(private val gen: suspend () -> T) {
	var started = false
	val deferred = Promise.Deferred<T>()

	suspend fun get(): T {
		if (!started) {
			started = true
			gen.startCoroutine(deferred.toContinuation())
		}
		return deferred.promise.await()
	}
}
