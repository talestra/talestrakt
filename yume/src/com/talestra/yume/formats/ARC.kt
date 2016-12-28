package com.talestra.yume.formats

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.Vfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsStat
import com.talestra.rhcommon.io.PackageReader
import java.io.File
import java.io.FileNotFoundException

object ARC : PackageReader {
	private data class Extension(val name: String, val count: Int, val start: Int)
	private data class FileRef(val name: String, val size: Int, val offset: Int)

	private const val EXT_RECORD_SIZE = (4 + 4 + 4)
	private const val FILE_RECORD_SIZE = (9 + 4 + 4)

	private fun SyncStream.readArcExt() = Extension(name = readStringz(4), count = readS32_le(), start = readS32_le())
	private fun SyncStream.readArcFileRef() = FileRef(name = readStringz(9), size = readS32_le(), offset = readS32_le())

	private fun SyncStream.write(v: Extension) {
		this.writeStringz(v.name, 4)
		this.write32_le(v.count)
		this.write32_le(v.start)
	}

	private fun SyncStream.write(v: FileRef) {
		this.writeStringz(v.name, 9)
		this.write32_le(v.size)
		this.write32_le(v.offset)
	}

	suspend fun read(s: AsyncStream): VfsFile = asyncFun {
		val extensionCount = s.readS32_le()
		val extensionData = s.readBytes(extensionCount * 12).open()
		val exts = (0 until extensionCount).map {
			Extension(name = extensionData.readStringz(4), count = extensionData.readS32_le(), start = extensionData.readS32_le())
		}
		val files = exts.flatMap { ext ->
			val s2 = s.sliceWithSize(ext.start.toLong(), (ext.count * (9 + 4 + 4)).toLong()).readAvailable().open()
			val refs = (0 until ext.count).map {
				FileRef(
					name = s2.readStringz(9),
					size = s2.readS32_le(),
					offset = s2.readS32_le()
				)
			}
			refs.map { "${it.name}.${ext.name}".trim().toUpperCase() to s.sliceWithSize(it.offset.toLong(), it.size.toLong()) }
		}.toMap()

		object : Vfs() {
			fun getEntry(path: String) = files[path.trim().toUpperCase()]

			override fun readBytesAsync(path: String): Promise<ByteArray> = async {
				readBytesAsync(path, 0L, statAsync(path).await().length).await()
			}

			override fun readBytesAsync(path: String, start: Long, end: Long): Promise<ByteArray> = async {
				val entry = getEntry(path) ?: throw FileNotFoundException("$path")
				entry.slice().readInternalAsync(start, end).await()
			}

			override fun statAsync(path: String): Promise<VfsStat> = async {
				val entry = getEntry(path)
				if (entry != null) {
					VfsStat(file(path), true, entry.length)
				} else {
					VfsStat(file(path), false, 0L)
				}
			}

			override fun listAsync(path: String): AsyncStream<VfsStat> = generateAsync {
				for ((name, stream) in files) {
					//println("$name: $stream")
					emit(VfsStat(file(name), true, stream.length))
				}
			}
		}.root
	}

	override fun read(s: SyncStream): Map<String, SyncStream> {
		val exsts = (0 until s.readS32_le()).map { s.readArcExt() }
		val files = exsts.flatMap { ext ->
			val s2 = s.sliceWithStart(ext.start)
			val refs = (0 until ext.count).map { s2.readArcFileRef() }
			refs.map { "${it.name}.${ext.name}" to s.slice(it.offset until it.offset + it.size) }
		}
		return files.toMap()
	}

	override fun write(s: SyncStream, files: Map<String, SyncStream>) {
		val itemsByExtension = files.entries.groupBy { File(it.key).extension }
		val RECORDS_OFFSET = 4 + EXT_RECORD_SIZE * itemsByExtension.size
		val CONTENT_OFFSET = RECORDS_OFFSET + FILE_RECORD_SIZE * files.size

		val s_ext = s.sliceWithStart(0)
		val s_file = s.sliceWithStart(RECORDS_OFFSET.toLong())
		val s_content = s.sliceWithStart(CONTENT_OFFSET.toLong())

		s_ext.write32_le(itemsByExtension.size)
		for ((ext, files2) in itemsByExtension) {
			s_ext.write(ARC.Extension(ext, files2.size, (RECORDS_OFFSET + s_file.position).toInt()))
			for (file in files2) {
				s_file.write(ARC.FileRef(File(file.key).nameWithoutExtension, file.value.length.toInt(), (CONTENT_OFFSET + s_content.position).toInt()))
				s_content.writeStream(file.value);
			}
		}

		//println(itemsByExtension)
	}
}