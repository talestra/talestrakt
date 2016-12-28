package com.talestra.toe

import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.mapWhile

object PakBDPair {
	fun parseDFile(b: SyncStream): List<SyncStream> {
		val count = b.readU32_le()
		val offsets = (0 until count).map { b.readU32_le() } + listOf(b.length)
		return (0 until offsets.size - 1).map { b.slice(offsets[it] until offsets[it + 1]) }
	}

	fun parseB_DPair(b: SyncStream, d: SyncStream): List<SyncStream> {
		val offsets = mapWhile({ !b.eof }) { b.readS32_le() }
		return (0 until offsets.size - 1).map { d.slice(offsets[it + 0] until offsets[it + 1]) }
	}
}