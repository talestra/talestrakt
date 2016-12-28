package com.talestra.yume.formats

import com.jtransc.JTranscSystem
import com.jtransc.annotation.JTranscUnsafeFastArrays
import com.jtransc.target.Js
import com.talestra.rhcommon.compression.LZEncoder
import java.io.ByteArrayOutputStream

object WillLZ {
	// @TODO: This should be unnecessary after a proper relooper is implemented
	@Suppress("UNUSED_PARAMETER")
	fun decompressFastJs(src: ByteArray, dst: ByteArray): Unit {
		Js.v_raw("""
			var ringbuf = new Uint8Array(0x1000);
			var srcv = new Uint8Array(p0.getBuffer());
			var dstv = new Uint8Array(p1.getBuffer());
			var src = 0;
			var end = srcv.length;
			var ringpos_write = 1;
			var dst = 0;

			while (src < end) {
				var ops = (srcv[src++] | 0x100); // Read operation
				while (ops != 1) {
					// Uncompressed
					if ((ops & 1) != 0) {
						ringbuf[ringpos_write++] = dstv[dst++] = srcv[src++];
						ringpos_write &= 0xFFF;
					} else {
						if (src >= end) break;
						var data = (srcv[src++] << 8) | (srcv[src++]);
						var count = (data & 0xF) + 2;
						var ringpos_read = (data >> 4);
						if (ringpos_read == 0) break;
						while (count-- > 0) {
							ringbuf[ringpos_write++] = dstv[dst++] = ringbuf[ringpos_read++];
							ringpos_write &= 0xFFF;
							ringpos_read &= 0xFFF;
						}
					}

					ops >>= 1;
					src |= 0;
					dst |= 0;
				}
			}
		""")
	}

	@JTranscUnsafeFastArrays
	fun decompressGeneric(srcv: ByteArray, dstv: ByteArray): Unit {
		val ringbuf = ByteArray(0x1000)
		var src = 0
		val end = srcv.size
		var ringpos_write = 1
		var dst = 0
		while (src < end) {
			var ops = ((srcv[src++].toInt() and 0xFF) or 0x100) // Read operation
			while (ops != 1) {
				// Uncompressed
				if ((ops and 1) != 0) {
					val v = srcv[src++].toInt() and 0xFF
					dstv[dst++] = v.toByte()
					ringbuf[ringpos_write++] = v.toByte()
					ringpos_write = ringpos_write and 0xFFF
				} else {
					if (src >= end) break
					val data = ((srcv[src++].toInt() and 0xFF) shl 8) or (srcv[src++].toInt() and 0xFF)
					var count = (data and 0xF) + 2
					var ringpos_read = (data ushr 4)
					if (ringpos_read == 0) break
					while (count-- > 0) {
						val c = ringbuf[ringpos_read++]
						dstv[dst++] = c
						ringbuf[ringpos_write++] = c
						ringpos_write = ringpos_write and 0xFFF
						ringpos_read = ringpos_read and 0xFFF
					}
				}

				ops = ops ushr 1
			}
		}
	}

	fun decompress(srcv: ByteArray, dstv: ByteArray): ByteArray {
		if (JTranscSystem.isJs()) {
			decompressFastJs(srcv, dstv)
		} else {
			decompressGeneric(srcv, dstv)
		}
		return dstv
	}

	fun compress(uncompressed: ByteArray): ByteArray {
		val encoder = object : LZEncoder() {
			var flags = 0
			var bit = 0
			val buffer = ByteArrayOutputStream()

			override fun processInit() {
				flags = 0
				bit = 0
			}

			private fun writeChunk() {
				output(flags and 0xFF)
				output(buffer.toByteArray())
				buffer.reset()
				processInit()
			}

			override fun processUncompressedByte(v: Int) {
				flags = flags.setBit(bit++)
				buffer.write(v)
				if (bit == 8) writeChunk()
			}

			override fun processEnd() {
				if (bit != 0) writeChunk()
			}
		}
		return encoder.encode(uncompressed)
	}
}