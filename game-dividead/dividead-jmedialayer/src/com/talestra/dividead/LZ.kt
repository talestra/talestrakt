package com.talestra.dividead

import com.jtransc.io.ra.RAByteArray
import jmedialayer.util.FastMemByte

/*
object LZ {
	@JvmStatic fun isCompressed(data: ByteArray): Boolean = RAByteArray(data).readStringz(2) == "LZ"

	@JvmStatic fun getUncompressedSize(data: ByteArray): Int = RAByteArray(data).sliceAvailable(6).readS32_LE()

	@JvmStatic fun uncompress(data: ByteArray): ByteArray {
		val sdata = RAByteArray(data)
		val magic = sdata.readStringz(2)
		val compressedSize = sdata.readS32_LE()
		val uncompressedSize = sdata.readS32_LE()
		if (magic != "LZ") throw RuntimeException("Invalid LZ stream")
		return _decodeFast(sdata.readBytes(compressedSize.toLong()), uncompressedSize)
	}

	@JvmStatic private fun _decodeFast(input: ByteArray, uncompressedSize: Int): ByteArray {
		var ip = 0
		val il = input.size


		val o2 = ByteArray(uncompressedSize + 0x1000)
		var op = 0x1000
		val ringStart = 0xFEE

		FastMemByte.selectSRC(input)
		FastMemByte.selectDST(o2)

		while (ip < il) {
			var code = FastMemByte.getSRC_u(ip++) or 0x100

			while (code != 1) {
				// Uncompressed
				if ((code and 1) != 0) {
					FastMemByte.setDST(op++, FastMemByte.getSRC_u(ip++))
				}
				// Compressed
				else {
					if (ip >= il) break
					val paramL = FastMemByte.getSRC_u(ip++)
					val paramH = FastMemByte.getSRC_u(ip++)
					val param = paramL or (paramH shl 8)
					val ringOffset = extractPosition(param)
					val ringLength = extractCount(param)
					val convertedP2 = ((ringStart + op) and 0xFFF) - ringOffset
					val convertedP = if (convertedP2 < 0) convertedP2 + 0x1000 else convertedP2
					val outputReadOffset = op - convertedP
					for (n in 0 until ringLength) {
						FastMemByte.setDST(op + n, FastMemByte.getDST_u(outputReadOffset + n))
					}
					op += ringLength
				}

				code = code ushr 1
			}
		}

		return o2.copyOfRange(0x1000, 0x1000 + uncompressedSize)
	}

	@JTranscInline @JvmStatic private fun extractPosition(param: Int): Int = (param and 0xFF) or ((param ushr 4) and 0xF00)
	@JTranscInline @JvmStatic private fun extractCount(param: Int): Int = ((param ushr 8) and 0xF) + 3
}
	*/
