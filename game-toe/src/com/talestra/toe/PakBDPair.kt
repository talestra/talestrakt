package com.talestra.toe

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.readS32_le
import com.soywiz.korio.stream.readU32_le
import com.soywiz.korio.stream.slice
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.lang.mapWhile

object PakBDPair {
	suspend fun parseDFile(b: AsyncStream): VfsFile = asyncFun {
		val count = b.readU32_le()
		val offsets = (0 until count).map { b.readU32_le() } + listOf(b.getLength())
		MemoryVfs((0 until offsets.size - 1).map { "$it" to b.slice(offsets[it] until offsets[it + 1]) }.toMap())
	}

	suspend fun parseB_DPair(b: AsyncStream, d: AsyncStream): VfsFile = asyncFun {
		val offsets = mapWhile({ !b.eof() }) { b.readS32_le() }
		MemoryVfs((0 until offsets.size - 1).map { "$it" to d.slice(offsets[it + 0] until offsets[it + 1]) }.toMap())
	}
}