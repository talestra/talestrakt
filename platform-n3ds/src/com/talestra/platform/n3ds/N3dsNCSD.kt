package com.talestra.platform.n3ds

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*

// https://www.3dbrew.org/wiki/NCSD
// .3ds files
object N3dsNCSD {
	suspend fun read(s: AsyncStream) = asyncFun {
		val header = s.readBytes(0x1600).openSync()
		header.apply {
			val rsa = readBytes(0x100)
			val magic = readStringz(4)
			if (magic != "NCSD") throw IllegalArgumentException("Not a NCSD file")
			val size = readS32_le()
			println(size)
		}
	}
}