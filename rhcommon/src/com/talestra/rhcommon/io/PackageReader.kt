package com.talestra.rhcommon.io

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.MemorySyncStream
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.toAsync
import com.soywiz.korio.vfs.VfsOpenMode
import com.soywiz.korio.vfs.open
import java.io.File

interface PackageReader {
	fun read(s: AsyncStream): Map<String, AsyncStream>
	fun write(s: AsyncStream, files: Map<String, AsyncStream>)
}

operator fun PackageReader.invoke(s: SyncStream): Map<String, AsyncStream> = read(s.toAsync())
suspend operator fun PackageReader.invoke(s: AsyncStream): Map<String, AsyncStream> = asyncFun { read(s) }
suspend operator fun PackageReader.invoke(s: File): Map<String, AsyncStream> = asyncFun { read(s.open(VfsOpenMode.READ)) }

fun PackageReader.generate(items: Map<String, AsyncStream>): ByteArray {
	val out = MemorySyncStream()
	write(out.toAsync(), items)
	return out.toByteArray()
}

