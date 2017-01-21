package com.talestra.toe

import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.readS32_le
import com.soywiz.korio.stream.readU32_le
import com.soywiz.korio.stream.slice
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.lang.mapWhile

object PakBDPair {
	suspend fun parseDFile(b: AsyncStream): VfsFile {
		val count = b.readU32_le()
		val offsets = (0 until count).map { b.readU32_le() } + listOf(b.getLength())
		return MemoryVfs((0 until offsets.size - 1).map { "$it" to b.slice(offsets[it] until offsets[it + 1]) }.toMap())
	}

	suspend fun parseB_DPair(b: AsyncStream, d: AsyncStream): VfsFile {
		val offsets = mapWhile({ !b.eof() }) { b.readS32_le() }
		return MemoryVfs((0 until offsets.size - 1).map { "$it" to d.slice(offsets[it + 0] until offsets[it + 1]) }.toMap())
	}
}