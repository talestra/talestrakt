package com.talestra.dividead

import com.soywiz.korio.stream.*
import com.soywiz.korio.util.ByteArraySlice
import com.soywiz.korio.util.UByteArray
import com.soywiz.korio.util.readS32_le

object LZ {
	fun isCompressed(data: ByteArray): Boolean = data.openSync("r").readStringz(2) == "LZ"

	fun getUncompressedSize(data: ByteArray): Int = data.readS32_le(6)

	fun uncompress(data: ByteArray): ByteArray {
		val sdata = data.openSync()
		val magic = sdata.readStringz(2)
		var compressedSize = sdata.readS32_le()
		val uncompressedSize = sdata.readS32_le()
		if (magic != "LZ") throw RuntimeException("Invalid LZ stream")
		return _decode(sdata, uncompressedSize)
	}

	private fun _decode(input: SyncStream, uncompressedSize: Int): ByteArray {
		return _decodeFast((input.base as MemorySyncStreamBase).data.toByteArraySlice(input.position), uncompressedSize)
	}

	private fun _decodeFast(input: ByteArraySlice, uncompressedSize: Int): ByteArray {
		val i = UByteArray(input.data)
		var ip = input.position
		val il = input.length

		val o = UByteArray(uncompressedSize + 0x1000)
		var op = 0x1000
		val ringStart = 0xFEE

		while (ip < il) {
			var code = i[ip++] or 0x100

			while (code != 1) {
				// Uncompressed
				if ((code and 1) != 0) {
					o[op++] = i[ip++]
				}
				// Compressed
				else {
					if (ip >= il) break
					val paramL = i[ip++]
					val paramH = i[ip++]
					val param = paramL or (paramH shl 8)
					val ringOffset = extractPosition(param)
					val ringLength = extractCount(param)
					val convertedP2 = ((ringStart + op) and 0xFFF) - ringOffset
					val convertedP = if (convertedP2 < 0) convertedP2 + 0x1000 else convertedP2
					val outputReadOffset = op - convertedP
					for (n in 0 until ringLength) o[op + n] = o[outputReadOffset + n]
					op += ringLength
				}

				code = code ushr 1
			}
		}

		return o.data.copyOfRange(0x1000, 0x1000 + uncompressedSize)
	}

	private fun extractPosition(param: Int): Int = (param and 0xFF) or ((param ushr 4) and 0xF00)
	private fun extractCount(param: Int): Int = ((param ushr 8) and 0xF) + 3
}