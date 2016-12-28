package com.talestra.dividead

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.async.toList
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.io.PackageReader
import java.util.*

object DL1 : PackageReader {
	override suspend fun read(s: AsyncStream): VfsFile = asyncFun {
		val magic = s.readStringz(8)
		val count = s.readU16_le()
		val offset = s.readS32_le()
		val padding = s.readU16_le()

		if (magic != "DL1.0\u001A") throw RuntimeException("Not a DL1 file")

		val s2 = s.slice(offset until offset + count * 0x10).readAll().openSync("r")

		val files = LinkedHashMap<String, AsyncStream>()

		var pos = 0x10
		for (n in 0 until count) {
			val name = s2.readStringz(12)
			val size = s2.readS32_le()
			files[name] = s.slice(pos until pos + size)
			pos += size
		}

		MemoryVfs(files)
	}

	override suspend fun write(s: AsyncStream, root: VfsFile): Unit = asyncFun {
		val entries = root.listRecursive().toList()

		s.writeStringz("DL1.0\u001A", 8)
		s.write16_le(entries.size)
		s.write32_le(0x10 + entries.sumBy { it.size().toInt() })
		s.write16_le(0) // padding
		for (file in entries) s.writeStream(file.open())
		for (file in entries) {
			s.writeStringz(file.fullname, 12)
			s.write32_le(file.size())
		}
	}
}

suspend fun AsyncStream.openAsDL1() = DL1.read(this)
suspend fun VfsFile.openAsDL1() = asyncFun { DL1.read(this.open()) }