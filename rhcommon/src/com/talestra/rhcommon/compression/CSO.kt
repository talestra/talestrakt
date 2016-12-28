package com.talestra.rhcommon.compression

import com.soywiz.korio.stream.*

object CSO {
	const val MAGIC = "CISO"

	data class Header(
		val magic: String,
		val headerSize: Int,
		val totalBytes: Long,
		val blockSize: Int,
		val version: Int,
		val alignment: Int,
		val reserved: Int
	) {
		constructor(s: SyncStream) : this(
			magic = s.readStringz(4),
			headerSize = s.readS32_le(),
			totalBytes = s.readS64_le(),
			blockSize = s.readS32_le(),
			version = s.readU8(),
			alignment = s.readU8(),
			reserved = s.readU16_le()
		) {
			if (magic != MAGIC) throw IllegalArgumentException("Not a CISO file")
		}

		val numberOfBlocks: Int get() = (this.totalBytes / this.blockSize).toInt()
	}

	class CsoStream2(val parent: SyncStream) : SyncStream() {
		val header = Header(parent)
		val chunks = parent.readIntArray_le(header.numberOfBlocks + 1).toList()
		val blockSize = header.blockSize
		private var cachedBlock: Int = -1
		private var cachedBlockData: ByteArray = ByteArray(blockSize)

		override var length: Long = header.totalBytes

		fun readBlock(n: Int, out: ByteArray, outOffset: Int): ByteArray {
			if (n != cachedBlock) {
				val isCompressed = (chunks[n + 0] and 0x80000000.toInt()) === 0
				val start = chunks[n + 0] and 0x7FFFFFFF
				val end = chunks[n + 1] and 0x7FFFFFFF

				val raw = parent.sliceWithBounds(start.toLong(), end.toLong()).readAll()
				val uncompressed = if (isCompressed) Compression.uncompressZlibNowrap(raw) else raw

				cachedBlock = n
				System.arraycopy(uncompressed, 0, cachedBlockData, 0, blockSize)
			}
			System.arraycopy(cachedBlockData, 0, out, outOffset, blockSize)
			return out
		}

		fun readBlocks(start: Int, endInclusive: Int): ByteArray {
			val actualEndInclusive = Math.min(endInclusive, header.numberOfBlocks - 1)
			// Fast on small reads
			if ((start == actualEndInclusive) && (start == cachedBlock)) {
				return cachedBlockData
			} else {
				val blocks = ByteArray((actualEndInclusive - start + 1) * blockSize)
				for (n in start..actualEndInclusive) readBlock(n, blocks, (n - start) * blockSize)
				return blocks
			}
		}

		override fun read(buffer: ByteArray, offset: Int, len: Int): Int {
			return super.read(buffer, offset, len)
		}

		override fun readInternal(position: Long, bytes: ByteArray, offset: Int, count: Int): Int {
			val end = Math.min(position + count, header.totalBytes)
			val readata = readBlocks((position / blockSize).toInt(), (end / blockSize).toInt())
			val readoffset = (position % blockSize).toInt()
			val actualCount = Math.min(readata.size - readoffset, (end - position).toInt())
			System.arraycopy(readata, readoffset, bytes, offset, actualCount)
			return actualCount
		}
	}

	fun read(s: SyncStream): CsoStream2 = CsoStream2(s)
}