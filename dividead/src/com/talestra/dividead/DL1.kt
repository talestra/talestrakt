package com.talestra.dividead

import com.soywiz.korio.stream.*
import com.talestra.rhcommon.io.PackageReader
import java.util.*

object DL1 : PackageReader {
	override fun read(s: SyncStream): Map<String, SyncStream> {
		val magic = s.readStringz(8)
		val count = s.readU16_le()
		val offset = s.readS32_le()
		val padding = s.readU16_le()

		if (magic != "DL1.0\u001A") throw RuntimeException("Not a DL1 file")

		val s2 = s.slice(offset until offset + count * 0x10).readAll().openSync("r")

		val files = LinkedHashMap<String, SyncStream>()

		var pos = 0x10
		for (n in 0 until count) {
			val name = s2.readStringz(12)
			val size = s2.readS32_le()
			files[name] = s.slice(pos until pos + size)
			pos += size
		}

		return files
	}

	override fun write(s: SyncStream, files: Map<String, SyncStream>) {
		val entries = files.toList()

		s.writeStringz("DL1.0\u001A", 8)
		s.write16_le(files.size)
		s.write32_le(0x10 + entries.sumBy { it.second.length.toInt() })
		s.write16_le(0) // padding
		for ((name, data) in entries) s.writeStream(data)
		for ((name, data) in entries) {
			s.writeStringz(name, 12)
			s.write32_le(data.length.toInt())
		}
	}
}