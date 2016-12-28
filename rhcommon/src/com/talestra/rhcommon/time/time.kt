package com.talestra.rhcommon.time

import java.util.*

enum class Month(val index: Int) {
	January(1), February(2), March(3), April(4), June(5),
	July(7), August(8), September(9), October(10), November(11), December(12)
}

enum class DayOfWeek(val index: Int) {
	Sunday(0), Monday(1), Tuesday(2), Wednesday(3), Thursday(4), Friday(5), Saturday(6)
}

data class TimeSpan internal constructor(private val ms: Int) {
	override fun toString(): String = "${seconds}s"
	val milliseconds: Int get() = ms
	val seconds: Double get() = ms / 1000.0

	operator fun plus(that: TimeSpan) = TimeSpan(this.ms + that.ms)
	operator fun minus(that: TimeSpan) = TimeSpan(this.ms - that.ms)
	operator fun times(count: Int) = TimeSpan((this.ms * count.toDouble()).toInt())
	operator fun div(count: Int) = TimeSpan((this.ms / count.toDouble()).toInt())
	operator fun times(count: Double) = TimeSpan((this.ms * count.toDouble()).toInt())
	operator fun div(count: Double) = TimeSpan((this.ms / count.toDouble()).toInt())
	operator fun compareTo(that: TimeSpan): Int = this.ms.compareTo(that.ms)

	companion object {
		fun fromSeconds(value: Double) = TimeSpan((value.toDouble() * 1000).toInt())
		fun fromMilliseconds(value: Double) = TimeSpan(value.toInt())
		fun fromMicroseconds(value: Double) = TimeSpan((value.toLong() / 1000L).toInt())

		fun fromSeconds(value: Int) = TimeSpan((value.toDouble() * 1000).toInt())
		fun fromMilliseconds(value: Int) = TimeSpan(value.toInt())
		fun fromMicroseconds(value: Int) = TimeSpan((value.toLong() / 1000L).toInt())

		fun fromSeconds(value: Long) = TimeSpan((value.toDouble() * 1000).toInt())
		fun fromMilliseconds(value: Long) = TimeSpan(value.toInt())
		fun fromMicroseconds(value: Long) = TimeSpan((value.toLong() / 1000L).toInt())

		fun millisecondsToSeconds(value: Int): Double = value.toDouble() / 1000.0
		fun secondsToMilliseconds(value: Double): Int = (value * 1000.0).toInt()
	}

	fun roundToSeconds() = fromSeconds(seconds.toInt())
}

data class DateTime internal constructor(val timestamp: Long) {
	val month: Month get() = Month.January
	val date: Date get() = Date(timestamp)

	operator fun minus(that: DateTime) = TimeSpan((this.timestamp - that.timestamp).toInt())
	operator fun plus(that: TimeSpan) = DateTime(this.timestamp + that.milliseconds)

	//fun now(): DateTime {
	//	System.currentTimeMillis()
	//}

	operator fun compareTo(that: DateTime) = this.timestamp.compareTo(that.timestamp)

	companion object {
		val zero: DateTime = DateTime(0L)
		fun nowMillis(): Long = System.currentTimeMillis()
		fun now(): DateTime = DateTime(nowMillis())
	}
}

fun Date.toDateTime(): DateTime = DateTime(this.time)

public fun TimeSpan.toMinutesString(): String {
	var time: Int = this.seconds.toInt()
	val minutes: Int = Math.floor(time / 60.0).toInt();
	time %= 60
	val seconds = time;
	return "%d:%02d".format(minutes, seconds)
}

fun TimeSpan.toHoursString(): String {
	val totalSeconds = this.seconds
	val seconds = (totalSeconds % 60).toInt()
	val minutes = Math.floor((totalSeconds % 3600) / 60).toInt()
	val hours = Math.floor(totalSeconds / (60 * 60)).toInt()

	return "%02d:%02d:%02d".format(hours, minutes, seconds)
}

@Deprecated("Bad design.")
public fun TimeSpan.Companion.stringToSeconds(stringDate: String): Double {
	//var date:Date = new Date();
	//date.setTime(Date.parse(stringDate));
	//return date.getTime() / 1000;
	throw NotImplementedError("Not implementeed stringToSeconds")
}

fun DateTime.plus(that: TimeSpan) = DateTime(this.timestamp.toLong() + that.milliseconds)

val Double.seconds: TimeSpan get() = TimeSpan.fromSeconds(this)
val Double.milliseconds: TimeSpan get() = TimeSpan.fromMilliseconds(this)

val Int.seconds: TimeSpan get() = TimeSpan.fromSeconds(this)
val Int.milliseconds: TimeSpan get() = TimeSpan.fromMilliseconds(this)

val Long.seconds: TimeSpan get() = TimeSpan.fromSeconds(this)
val Long.milliseconds: TimeSpan get() = TimeSpan.fromMilliseconds(this)

fun now() = DateTime(System.currentTimeMillis())
