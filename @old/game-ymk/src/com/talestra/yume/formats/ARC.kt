package com.talestra.yume.formats

import com.soywiz.korio.async.AsyncSequence
import com.soywiz.korio.async.asyncGenerate
import com.soywiz.korio.async.toList
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.Vfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode
import com.soywiz.korio.vfs.VfsStat
import com.talestra.rhcommon.io.PackageReader

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

	suspend override fun read(s: AsyncStream): VfsFile {
		val extensionCount = s.readS32_le()
		val extensionData = s.readBytes(extensionCount * 12).openSync()
		val exts = (0 until extensionCount).map {
			Extension(name = extensionData.readStringz(4), count = extensionData.readS32_le(), start = extensionData.readS32_le())
		}
		val files = exts.flatMap { ext ->
			val s2 = s.sliceWithSize(ext.start.toLong(), (ext.count * (9 + 4 + 4)).toLong()).readAvailable().openSync()
			val refs = (0 until ext.count).map {
				FileRef(
					name = s2.readStringz(9),
					size = s2.readS32_le(),
					offset = s2.readS32_le()
				)
			}
			refs.map { "${it.name}.${ext.name}".trim().toUpperCase() to s.sliceWithSize(it.offset.toLong(), it.size.toLong()) }
		}.toMap()

		return object : Vfs() {
			fun getEntry(path: String) = files[path.trim().toUpperCase()]

			suspend override fun open(path: String, mode: VfsOpenMode): AsyncStream = getEntry(path)!!.slice()

			suspend override fun stat(path: String): VfsStat {
				val entry = getEntry(path)
				return if (entry != null) {
					createExistsStat(path, isDirectory = false, size = entry.getLength())
				} else {
					createNonExistsStat(path)
				}
			}

			suspend override fun list(path: String): AsyncSequence<VfsFile> = asyncGenerate {
				for ((name, stream) in files) yield(file(name))
			}
		}.root
	}

	//override suspend fun read(s: AsyncStream): VfsFile {
	//	val exsts = (0 until s.readS32_le()).map { s.readArcExt() }
	//	val files = exsts.flatMap { ext ->
	//		val s2 = s.sliceWithStart(ext.start)
	//		val refs = (0 until ext.count).map { s2.readArcFileRef() }
	//		refs.map { "${it.name}.${ext.name}" to s.slice(it.offset until it.offset + it.size) }
	//	}
	//	return files.toMap()
	//}

	override suspend fun write(s: AsyncStream, root: VfsFile): Unit {
		val itemsByExtension = root.listRecursive().toList().groupBy { it.extension }
		val RECORDS_OFFSET = 4 + EXT_RECORD_SIZE * itemsByExtension.size
		val CONTENT_OFFSET = RECORDS_OFFSET + FILE_RECORD_SIZE * root.size()

		val s_ext = s.sliceWithStart(0)
		val s_file = s.sliceWithStart(RECORDS_OFFSET.toLong())
		val s_content = s.sliceWithStart(CONTENT_OFFSET.toLong())

		s_ext.write32_le(itemsByExtension.size)
		for ((ext, files2) in itemsByExtension) {
			s_ext.writeStringz(ext, 4)
			s_ext.write32_le(files2.size)
			s_ext.write32_le((RECORDS_OFFSET + s_file.getPosition()).toInt())
			for (file in files2) {
				s_file.writeStringz(file.basenameWithoutExtension, 9)
				s_file.write32_le(file.size().toInt())
				s_file.write32_le((CONTENT_OFFSET + s_content.getPosition()).toInt())
				s_content.writeFile(file)
			}
		}

		//println(itemsByExtension)
	}
}

suspend fun AsyncStream.openAsARC() = ARC.read(this)
suspend fun VfsFile.openAsARC() = ARC.read(this.open())