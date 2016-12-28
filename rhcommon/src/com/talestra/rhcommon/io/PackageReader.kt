package com.talestra.rhcommon.io

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.MemorySyncStream
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.toAsync
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode
import com.soywiz.korio.vfs.open
import java.io.File

interface PackageReader {
	suspend fun read(s: AsyncStream): VfsFile
	suspend fun write(s: AsyncStream, root: VfsFile)
}

suspend operator fun PackageReader.invoke(s: SyncStream) = asyncFun { read(s.toAsync()) }
suspend operator fun PackageReader.invoke(s: AsyncStream) = read(s)
suspend operator fun PackageReader.invoke(file: File) = asyncFun { read(LocalVfs(file).open(VfsOpenMode.READ)) }

suspend fun PackageReader.generate(root: VfsFile): ByteArray = asyncFun {
	val out = MemorySyncStream()
	write(out.toAsync(), root)
	out.toByteArray()
}

