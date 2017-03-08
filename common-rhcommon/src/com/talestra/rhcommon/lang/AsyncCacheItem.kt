package com.talestra.rhcommon.lang

import com.soywiz.korio.async.Promise
import com.soywiz.korio.coroutine.korioStartCoroutine

class AsyncCacheItem<T>(private val gen: suspend () -> T) {
	var started = false
	val deferred = Promise.Deferred<T>()

	suspend fun get(): T {
		if (!started) {
			started = true
			gen.korioStartCoroutine(deferred.toContinuation())
		}
		return deferred.promise.await()
	}
}
