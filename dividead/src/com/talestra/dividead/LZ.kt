package com.talestra.dividead

import com.soywiz.korio.stream.MemorySyncStream
import com.soywiz.korio.util.ByteArraySlice

object LZ {
	fun isCompressed(data: ByteArray): Boolean = data.open2("r").readStringz(2) == "LZ"

	fun getUncompressedSize(data: ByteArray): Int = BitRead.S32_le(data, 6)

	fun uncompress(data: ByteArray): ByteArray {
		val sdata = data.open2("r")
		val magic = sdata.readStringz(2)
		var compressedSize = sdata.readS32_le()
		val uncompressedSize = sdata.readS32_le()
		if (magic != "LZ") throw RuntimeException("Invalid LZ stream")
		return _decode(sdata, uncompressedSize)
	}

	private fun _decode(input: MemorySyncStream, uncompressedSize: Int): ByteArray {
		return measure("decoding image") { _decodeFast(input.toByteArraySlice(), uncompressedSize) }
	}

	private fun _decodeFast(input: ByteArraySlice, uncompressedSize: Int): ByteArray {
		val i = input.data
		var ip = input.position
		val il = input.length

		val o = ByteArray(uncompressedSize + 0x1000)
		var op = 0x1000
		val ringStart = 0xFEE

		while (ip < il) {
			var code = i.getu(ip++) or 0x100

			while (code != 1) {
				// Uncompressed
				if ((code and 1) != 0) {
					o[op++] = i[ip++]
				}
				// Compressed
				else {
					if (ip >= il) break
					val paramL = i.getu(ip++)
					val paramH = i.getu(ip++)
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

		return o.copyOfRange(0x1000, 0x1000 + uncompressedSize)
	}

	private fun extractPosition(param: Int): Int = (param and 0xFF) or ((param ushr 4) and 0xF00)
	private fun extractCount(param: Int): Int = ((param ushr 8) and 0xF) + 3
}