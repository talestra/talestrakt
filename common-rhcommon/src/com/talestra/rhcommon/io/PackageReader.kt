package com.talestra.rhcommon.io

import com.soywiz.korio.stream.*
import com.soywiz.korio.util.ByteArrayBuffer
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode
import java.io.File

interface PackageReader {
	suspend fun read(s: AsyncStream): VfsFile
	suspend fun write(s: AsyncStream, root: VfsFile)
}

suspend operator fun PackageReader.invoke(s: SyncStream) = read(s.toAsync())
suspend operator fun PackageReader.invoke(s: AsyncStream) = read(s)
suspend operator fun PackageReader.invoke(file: File) = read(LocalVfs(file).open(VfsOpenMode.READ))

suspend fun PackageReader.generate(root: VfsFile): ByteArray {
	val buffer = ByteArrayBuffer()
	val s = MemorySyncStream(buffer)
	write(s.toAsync(), root)
	return buffer.toByteArray()
}

// @TODO: Kotlin bug
//suspend fun PackageReader.generate(root: VfsFile): ByteArray {
//	return MemorySyncStreamToByteArray { write(toAsync(), root) }
//}

