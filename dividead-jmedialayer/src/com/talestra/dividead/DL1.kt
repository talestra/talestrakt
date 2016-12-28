package com.talestra.dividead

import com.jtransc.io.ra.RAByteArray
import com.jtransc.io.ra.RAStream
import jmedialayer.graphics.Bitmap
import jmedialayer.graphics.Bitmap32
import jmedialayer.imaging.BMP
import java.io.File
import java.util.*

class DL1(val files: Map<String, RAStream>) {
	companion object {
		fun read(s: RAStream): DL1 {
			//return DL1(mapOf())

			val magic = s.readStringz(8)
			val count = s.readU16_LE()
			val offset = s.readS32_LE()
			val padding = s.readU16_LE()

			if (magic != "DL1.0\u001A") throw RuntimeException("Not a DL1 file")

			val s2 = RAByteArray(s.slice(offset.toLong(), (offset + count * 0x10).toLong()).readAvailableBytes())

			val files = LinkedHashMap<String, RAStream>()

			var pos = 0x10
			for (n in 0 until count) {
				val name = s2.readStringz(12)
				val size = s2.readS32_LE()
				files[name] = s.slice(pos.toLong(), (pos + size).toLong())
				pos += size
			}

			return DL1(files)
		}
	}

	fun getNameWithExtension(name: String, ext: String): String = File(name).nameWithoutExtension + ".$ext"
	fun readStream(name: String): RAStream = files[name]!!.sliceAvailable(0L)
	fun readBytes(name: String): ByteArray = files[name]?.sliceAvailable(0L)?.readAvailableBytes() ?: ByteArray(0)
	fun readScriptStream(name: String): RAStream = RAByteArray(readBytes(getNameWithExtension(name, "AB")))

	fun readImage(name: String): Bitmap {
		val path2 = getNameWithExtension(name, "BMP")
		val compressedBytes = readBytes(path2)
		if (compressedBytes.isEmpty()) return Bitmap32(300, 300)
		return BMP().read(LZ.uncompress(compressedBytes))
	}
}