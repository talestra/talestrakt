package com.talestra.shny.play

import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.openAsIso

class GameIso(
	val root: VfsFile
) {
	companion object {
		suspend fun fromIso(stream: AsyncStream): GameIso {
			GameIso(stream.openAsIso())
		}
	}
}