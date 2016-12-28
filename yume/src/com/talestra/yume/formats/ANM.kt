package com.talestra.yume.formats

import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.readStringz
import com.soywiz.korio.stream.readU16_le
import com.talestra.rhcommon.ds.IntArray2

class ANM(
	val wipName: String,
	val map: IntArray2
) {
	companion object {
		fun read(s: SyncStream): ANM {
			val map = IntArray2(402, 100)
			val name = s.readStringz(9)
			for (y in 0 until map.height) {
				for (x in 0 until map.width) {
					map[x, y] = s.readU16_le()
				}
			}
			return ANM(name, map)
		}
	}
}