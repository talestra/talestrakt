package com.talestra.games.hanabira

import com.soywiz.korio.error.invalidOp
import com.soywiz.korio.serialization.binary.*
import com.soywiz.korio.stream.*
import com.soywiz.korio.util.fromHexString
import com.soywiz.korio.vfs.NodeVfs
import com.soywiz.korio.vfs.VfsFile

object FJSYS {
	@LE
	data class Header(
			@Order(0) @Count(8) @Encoding("UTF-8") val magic: String,
			@Order(1) val table_files_start: Int,
			@Order(2) val table_strings_size: Int,
			@Order(3) val count: Int
	) : Struct

	data class EntryHeaders(@Order(0) val dummy: Int, @Order(1) val nameStart: Int, @Order(2) val size: Int, @Order(3) val position: Int) : Struct

	data class Entry(val name: String, val position: Long, val size: Long, val stream: AsyncStream)

	suspend fun read(s: AsyncStream): ArrayList<Entry> {
		val h = s.readStruct<Header>()
		if (h.magic != "FJSYS") invalidOp("Expected FJSYS")

		val table_strings_start = 0x54 + h.count * 0x10
		val table_files_start = table_strings_start + h.table_strings_size
		if (h.table_files_start != table_files_start) invalidOp("Calculated table_files_start mismatch")

		val table = s.sliceWithSize(0x50, (h.count * 0x10).toLong()).readAll().openSync()
		val strings = s.sliceWithSize(table_strings_start.toLong(), h.table_strings_size.toLong())

		val entries = arrayListOf<Entry>()

		for (n in 0 until h.count) {
			val e = table.readStruct<EntryHeaders>()
			val position = e.position.toLong()
			val size = e.size.toLong()
			val name = strings.sliceWithStart(e.nameStart.toLong()).readStringz()

			entries += Entry(name, position, size, s.sliceWithSize(position, size))
		}

		return entries
	}
}

suspend fun VfsFile.openFJSYS(): VfsFile {
	val out = NodeVfs()
	for (e in FJSYS.read(this.open())) {
		out.rootNode.createChild(e.name).stream = e.stream
	}
	return out.root
}