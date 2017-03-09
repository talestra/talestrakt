package com.talestra.games.toa.platform.n3ds

import com.soywiz.korio.stream.*
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.zip.Inflater
import java.util.zip.InflaterInputStream

object TLZC {
	fun decompress(s: SyncStream): ByteArray {
		if (s.readStringz(4) != "TLZC") throw IllegalArgumentException("Not a TLZC file")
		if (s.readS32_be() != 0x01020000) throw IllegalArgumentException("Not a TLZC file version 0x01010000")
		val compressedSize = s.readS32_le()
		val uncompressedSize = s.readS32_le()
		s.readS32_le()
		s.readS32_le()
		val out = ByteArrayOutputStream(uncompressedSize)
		val inp = ByteArrayInputStream(s.readBytes(compressedSize))
		val inflater = Inflater(true)
		InflaterInputStream(inp, inflater).copyTo(out)
		return out.toByteArray()
	}
}