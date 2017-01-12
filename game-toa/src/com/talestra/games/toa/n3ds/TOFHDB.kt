package com.talestra.games.toa.n3ds

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.serialization.binary.*
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.MemoryVfs

// NAME_HASH -> FILE_ENTRY -> SLICE
object TOFHDB {
	data class Header(
		@Order(0) val time: Long,
		@Order(1) val fileHashArrayOffset: Int,
		@Order(2) val fileHashArrayCount: Int,
		@Order(3) val fileHashArrayByteSize: Long,
		@Order(4) val fileArrayOffset: Int,
		@Order(5) val fileArrayCount: Int,
		@Order(6) val fileArrayByteSize: Long
	) : Struct

	data class HashArray(
		@Order(0) val key: Int,
		@Order(1) val value: Int
	) : Struct

	data class FileStruct(
		@Order(0) val fileSize: Long,
		@Order(1) val compressSize: Long,
		@Order(2) val offset: Long,
		@Order(3) val hash: Int,
		@Order(4) @Count(12) @Encoding("UTF-8") val extension: String
	) : Struct

	suspend fun read(dbs: AsyncStream, dat: AsyncStream) = asyncFun {
		val dbss = dbs.readAll().openSync()
		val header = dbss.readStruct<Header>()

		//println(header)

		dbss.sliceWithStart(header.fileHashArrayOffset.toLong()).apply {
			val fileHashArray = (0 until header.fileHashArrayCount).map { readStruct<HashArray>() }
			//println(fileHashArray)
		}

		data class Info(val name: String, val file: FileStruct, val s: AsyncStream)

		val files = dbss.sliceWithStart(header.fileArrayOffset.toLong() + 24L).run {
			val files = (0 until header.fileArrayCount).map { readStruct<FileStruct>() }
			//for (file in files) println("" + file.offset + " : " + file.compressSize)
			files.map { file -> Info("%08X.%s".format(file.hash, file.extension), file, dat.sliceWithSize(file.offset, file.compressSize)) }
		}

		//for ((name, file, s) in files) {
		//	val dataSize = s.readAll().size
		//	println(dat.getLength())
		//	println(dataSize)
		//	if (dataSize == 0) {
		//		println("-")
		//	}
		//}
		//println(files.values.toList()[100].readAll().size)

		MemoryVfs(files.map { it.name to it.s }.toMap())
		//for ((name, data) in files) {
		//	println("$name: ${data.getLength()}")
		//}
	}
}