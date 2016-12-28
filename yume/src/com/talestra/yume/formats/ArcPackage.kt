package com.talestra.yume.formats

import WIP
import com.soywiz.korio.stream.SyncStream

class ArcPackage(val files: Map<String, SyncStream>) {
	fun getImage(name: String): List<WIP.Entry> {
		val color = files["$name.WIP"]
		val mask = files["$name.MSK"]
		if (color == null) {
			return listOf()
		} else if (mask == null) {
			return WIP.read(color)
		} else {
			val c = WIP.read(color)
			val m = WIP.read(mask)
			return WIP.combine(c, m)
		}
	}
}
