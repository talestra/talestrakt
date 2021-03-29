package com.talestra.games.toa.util

import com.soywiz.korio.stream.sliceWithStart
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.openAsIso

suspend fun VfsFile.openAsCVM(): VfsFile {
	return open().sliceWithStart(0x1800L).openAsIso()
}