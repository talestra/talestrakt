package com.talestra.rhcommon.compression

import java.io.ByteArrayOutputStream

open class LZEncoder {
	open val ringbufferSize: Int = 0x1000
	open val maxLzLength: Int = 15
	open val supportOverlapping: Boolean = false

	lateinit var ringBuffer: ByteArray
	var ringPos = 0

	var out = ByteArrayOutputStream()

	private fun init() {
		out = ByteArrayOutputStream()
		ringBuffer = ByteArray(ringbufferSize)
		ringPos = 0
		processInit()
	}

	private fun end() {
		processEnd()
	}

	fun encode(data: ByteArray): ByteArray {
		return encodeSimple(data)
	}

	private fun writeRing(v: Int) {
		ringBuffer[ringPos] = v.toByte()
		ringPos = (ringPos + 1) % ringbufferSize
	}

	open fun processInit() {
	}

	fun encodeSimple(data: ByteArray): ByteArray {
		init()
		for (v in data) {
			writeRing(v.toInt())
			processUncompressedByte(v.toInt())
		}
		end()
		return out.toByteArray()
	}

	protected fun output(b: Int) {
		out.write(b)
	}

	protected fun output(b: ByteArray, offset: Int = 0, size: Int = b.size) {
		out.write(b, offset, size)
	}

	open protected fun processUncompressedByte(v: Int) {
	}

	open protected fun processLZ(offset: Int, length: Int) {
	}

	open protected fun processRLE8(value: Int, length: Int) {
		if (supportOverlapping) {
			processUncompressedByte(value)
			processLZ(1, length)
		} else {
			// @TODO: Improve this without overlapping!
			for (n in 0 until length) processUncompressedByte(value)
		}
	}

	open protected fun processEnd() {

	}
}