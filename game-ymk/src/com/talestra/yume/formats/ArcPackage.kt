package com.talestra.yume.formats

import WIP
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.vfs.VfsFile

class ArcPackage(val files: VfsFile) {
	suspend fun getImage(name: String): List<WIP.Entry> = asyncFun {
		val color = files["$name.WIP"]
		val mask = files["$name.MSK"]
		if (!color.exists()) {
			listOf()
		} else if (!mask.exists()) {
			WIP.read(color.readAsSyncStream())
		} else {
			val c = WIP.read(color.readAsSyncStream())
			val m = WIP.read(mask.readAsSyncStream())
			WIP.combine(c, m)
		}
	}
}
