package com.talestra.dividead

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.Vfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode

class UncompressIfRequired(val parent: SyncStream) : SyncStreamBase() {
	val header = parent.slice(0 until 0x10).readAll()
	val isCompressed = LZ.isCompressed(header)

	override var length: Long = if (isCompressed) LZ.getUncompressedSize(header).toLong() else parent.length

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

	override fun read(position: Long, buffer: ByteArray, offset: Int, len: Int): Int {
		dataStream.position = position
		return dataStream.read(buffer, offset, len)
	}
}

fun VfsFile.uncompressIfRequired() = object : Vfs.Proxy() {
	val base = this@uncompressIfRequired
	suspend override fun access(path: String): VfsFile = base[path]
	suspend override fun open(path: String, mode: VfsOpenMode): AsyncStream = asyncFun { UncompressIfRequired(base[path].readAsSyncStream()).toAsync().toAsyncStream() }
}.root
