package com.talestra.rhcommon.lang

fun Boolean.toInt(): Int = if (this) 1 else 0

fun Byte.toU8(): Int = this.toInt() and 0xFF
fun Short.toU16(): Int = this.toInt() and 0xFFFF
fun Int.toU32(): Long = this.toLong() and 0xFFFFFFFFL

fun Int.setBit(bit: Int): Int = this or ((1 shl bit))
fun Int.clearBit(bit: Int): Int = this and ((1 shl bit)).inv()
fun Int.signExtend(bits: Int): Int = (this shl (32 - bits)) shr (32 - bits)
fun Int.zeroExtend(bits: Int): Int = (this and ((1 shl bits) - 1))

fun Int.isPowerOfTwo(): Boolean = this !== 0 && this and this.inv() + 1 === this
