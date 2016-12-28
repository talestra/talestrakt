package com.talestra.rhcommon.compression

import java.io.ByteArrayInputStream
import java.util.zip.Deflater
import java.util.zip.DeflaterInputStream
import java.util.zip.Inflater
import java.util.zip.InflaterInputStream

object Compression {
	fun uncompressZlib(data: ByteArray): ByteArray = InflaterInputStream(ByteArrayInputStream(data), Inflater()).readBytes()
	fun compressZlib(data: ByteArray, level: Int = 6): ByteArray = DeflaterInputStream(ByteArrayInputStream(data), Deflater(level)).readBytes()

	fun uncompressZlibNowrap(data: ByteArray): ByteArray = InflaterInputStream(ByteArrayInputStream(data), Inflater(true)).readBytes()
	fun compressZlibNowrap(data: ByteArray, level: Int = 6): ByteArray = DeflaterInputStream(ByteArrayInputStream(data), Deflater(level, true)).readBytes()
}
