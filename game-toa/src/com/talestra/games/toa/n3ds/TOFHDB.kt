package com.talestra.games.toa.n3ds

import com.soywiz.korio.serialization.binary.*
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.sliceWithStart

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

	data class File(
		@Order(0) val fileSize: Long,
		@Order(1) val compressSize: Long,
		@Order(2) val offset: Long,
		@Order(3) val hashValue: Int,
		@Order(4) @Count(12) @Encoding("UTF-8") val extension: String
	) : Struct

	fun read(s: SyncStream) {
		val header = s.readStruct<Header>()

		println(header)

		s.sliceWithStart(header.fileHashArrayOffset.toLong()).apply {
			val fileHashArray = (0 until header.fileHashArrayCount).map { readStruct<HashArray>() }
			//println(fileHashArray)
		}
		s.sliceWithStart(header.fileArrayOffset.toLong() + 24L).apply {
			val files = (0 until header.fileArrayCount).map { readStruct<File>() }
			for (file in files) {
				println(file)
			}
			//println(fileHashArray)
		}

	}
}