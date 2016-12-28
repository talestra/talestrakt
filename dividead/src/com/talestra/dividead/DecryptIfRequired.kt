package com.talestra.dividead

import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.readAll
import com.soywiz.korio.stream.slice

class UncompressIfRequired(parent: SyncStream) : SyncStream() {
	val header = parent.slice(0 until 0x10).readAll()
	val isCompressed = LZ.isCompressed(header)
	override val length: Long = if (isCompressed) LZ.getUncompressedSize(header).toLong() else parent.length
	val data by lazy {
		if (isCompressed) {
			LZ.uncompress(parent.readAll())
		} else {
			parent.readAll()
		}
	}
	val dataStream by lazy {
		data.openSync("r")
	}

	override fun readInternal(position: Long, bytes: ByteArray, offset: Int, count: Int): Int {
		return dataStream.readInternal(position, bytes, offset, count)
	}
}

fun Map<String, SyncStream>.uncompressIfRequired() = this.entries.map { it.key to UncompressIfRequired(it.value) }.toMap()
