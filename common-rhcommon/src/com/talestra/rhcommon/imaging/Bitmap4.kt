package com.talestra.rhcommon.imaging

import com.soywiz.korim.bitmap.Bitmap

class Bitmap4(width: Int, height: Int, var data: ByteArray = ByteArray(width * height / 2), var palette: IntArray = IntArray(16)) : Bitmap(width, height) {
	operator fun get(x: Int, y: Int): Int = (data[index(x, y) / 2].toInt() ushr (4 * (x % 2))) and 0xF
	override fun get32(x: Int, y: Int): Int = palette[this[x, y]]
}