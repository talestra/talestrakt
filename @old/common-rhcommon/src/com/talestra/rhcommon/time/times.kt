package com.talestra.rhcommon.time

interface Times : Iterable<Int> {
	companion object {
		val infinite: Times = InfiniteTimes
		val zero: Times by lazy { Companion(0) }
		val one: Times by lazy { Companion(1) }
		val two: Times by lazy { Companion(2) }
		val three: Times by lazy { Companion(3) }

		private val finiteCache = hashMapOf<Int, Times>()

		operator fun invoke(count: Int): Times {
			if (count in 0 until 10) {
				if (count !in finiteCache) finiteCache[count] = FiniteTimes(count)
				return finiteCache[count]!!
			} else {
				return FiniteTimes(count)
			}
		}
	}

	private object InfiniteTimes : Times {
		override fun iterator(): Iterator<Int> = (0 until Int.MAX_VALUE).iterator()

		override val hasMore = true
		override val decrementedByOne = this
	}

	private data class FiniteTimes(val count: Int) : Times {
		override fun iterator(): Iterator<Int> = (0 until count).iterator()
		override val hasMore = count > 0
		override val decrementedByOne by lazy { if (count == 0) this else Companion(count - 1) }
	}

	val hasMore: Boolean
	val decrementedByOne: Times

	operator fun compareTo(that: Times): Int {
		return when (this) {
			is InfiniteTimes -> if (that is FiniteTimes) +1 else 0
			is FiniteTimes -> if (that is FiniteTimes) this.count.compareTo(that.count) else -1
			else -> throw IllegalArgumentException("")
		}
	}
}

inline fun Times.exec(callback: (index: Int) -> Unit): Unit {
	for (n in this) callback(n)
}

val Int.times: Times get() = Times(this)
