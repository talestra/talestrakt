package com.talestra.platform.n3ds

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*

// https://www.3dbrew.org/wiki/ExeFS
object N3dsExtFS {
	suspend fun read(s: AsyncStream) = asyncFun {
		val header = s.readBytes(0x200).openSync()
		for (n in 0 until 10) {
			val filename = header.readStringz(8)
			val fileOffset = header.readU32_le()
			val fileSize = header.readU32_le()
		}
		header.position += 0x20
		val fileHashes = (0 until 10).map { header.readBytes(0x20) }
	}
}