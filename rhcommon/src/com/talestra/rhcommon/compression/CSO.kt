package com.talestra.rhcommon.compression

import com.soywiz.korio.async.asyncFun
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
		init {
			if (magic != MAGIC) throw IllegalArgumentException("Not a CISO file but '$magic'")
		}

		companion object {
			suspend operator fun invoke(s: AsyncStream) = asyncFun {
				Header(
					magic = s.readStringz(4),
					headerSize = s.readS32_le(),
					totalBytes = s.readS64_le(),
					blockSize = s.readS32_le(),
					version = s.readU8(),
					alignment = s.readU8(),
					reserved = s.readU16_le()
				)

			}
		}

		val numberOfBlocks: Int get() = (this.totalBytes / this.blockSize).toInt()
	}

	suspend fun read(s: AsyncStream): AsyncStream = asyncFun {
		val parent = s
		val header = Header(parent)
		val chunks = parent.readIntArray_le(header.numberOfBlocks + 1).toList()

		val blockSize = header.blockSize
		var cachedBlock: Int = -1
		var cachedBlockData: ByteArray = ByteArray(blockSize)
		var position = 0L

		class Impl : AsyncStream() {
			suspend override fun setPosition(value: Long) {
				position = value
			}

			suspend override fun getPosition(): Long {
				return position
			}

			suspend override fun getLength(): Long {
				return header.totalBytes
			}

			suspend fun readBlock(n: Int, out: ByteArray, outOffset: Int): ByteArray = asyncFun {
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
				out
			}

			suspend fun readBlocks(start: Int, endInclusive: Int): ByteArray = asyncFun {
				val actualEndInclusive = Math.min(endInclusive, header.numberOfBlocks - 1)
				// Fast on small reads
				if ((start == actualEndInclusive) && (start == cachedBlock)) {
					cachedBlockData
				} else {
					val blocks = ByteArray((actualEndInclusive - start + 1) * blockSize)
					for (n in start..actualEndInclusive) readBlock(n, blocks, (n - start) * blockSize)
					blocks
				}
			}

			suspend override fun read(buffer: ByteArray, offset: Int, len: Int): Int = asyncFun {
				val res = readInternal(position, buffer, offset, len)
				position += res
				res
			}

			suspend private fun readInternal(position: Long, bytes: ByteArray, offset: Int, count: Int): Int = asyncFun {
				val end = Math.min(position + count, header.totalBytes)
				val readata = readBlocks((position / blockSize).toInt(), (end / blockSize).toInt())
				val readoffset = (position % blockSize).toInt()
				val actualCount = Math.min(readata.size - readoffset, (end - position).toInt())
				System.arraycopy(readata, readoffset, bytes, offset, actualCount)
				actualCount
			}
		}

		Impl()
	}
}

suspend fun AsyncStream.cso() = CSO.read(this)