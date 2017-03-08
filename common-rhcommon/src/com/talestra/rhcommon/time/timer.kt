package com.talestra.rhcommon.time

import com.soywiz.korio.coroutine.korioSuspendCoroutine
import java.io.Closeable

class Timers : UpdatableGroup(), Closeable {
	override fun close() = removeAll()

	suspend fun wait(time: TimeSpan) = korioSuspendCoroutine<Unit> { c ->
		setTimeout(time, {
			c.resume(Unit)
		})
		//deferred.promise.cancelled {
		//	timeout.dispose()
		//}
	}

	fun setIntervalAndNow(time: TimeSpan, callback: () -> Unit): Closeable {
		callback()
		return setInterval(time, callback)
	}

	fun setInterval(time: TimeSpan, callback: () -> Unit): Closeable {
		var current = 0
		val total = time.milliseconds
		val updatable = object : Updatable {
			override fun update(dtMs: Int) {
				current += dtMs
				while (current >= total) {
					current -= total
					callback()
				}
			}
		}
		add(updatable)
		return Closeable { remove(updatable) }
	}

	fun setTimeout(time: TimeSpan, callback: () -> Unit): Closeable {
		var current = 0
		val total = time.milliseconds
		var updatable: Updatable? = null
		updatable = object : Updatable {
			override fun update(dtMs: Int) {
				current += dtMs
				if (current >= total) {
					remove(updatable!!)
					callback()
				}
			}
		}
		add(updatable)
		return Closeable { remove(updatable!!) }
	}
}
