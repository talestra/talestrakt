package com.talestra.yume.formats

import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.readAll
import com.talestra.rhcommon.io.generate
import org.junit.Assert
import org.junit.Test

class ARCTest {
	companion object {
		val RIO_ARC = ClassLoader.getSystemResource("Rio.arc").readBytes()
		val TITLE_WSC_decrypt = ClassLoader.getSystemResource("TITLE.WSC.decrypt").readBytes()
	}

	val rio by lazy { ARC.read(RIO_ARC.openSync("r")) }

	@Test
	fun testReadAndGenerateArc() {
		val original = RIO_ARC
		val files = ARC.read(original.openSync("r"))
		val generated = ARC.generate(files)
		Assert.assertArrayEquals(original, generated)
		Assert.assertEquals(164, files.size)
		Assert.assertEquals(listOf("A002_01.WSC", "A002_02.WSC", "A002_03A.WSC", "A002_03B.WSC", "A002_04.WSC"), files.keys.take(5))
	}

	@Test
	fun testReadScript() {
		val files = ARC.read(RIO_ARC.openSync("r"))
		val generated = WSC.Encryption.decrypt(files["TITLE.WSC"]!!.readAll())
		Assert.assertArrayEquals(TITLE_WSC_decrypt, generated)
	}

	@Test
	fun testParseScript() {
		val script = WSC.Encryption.decryptStream2(rio["A002_01.WSC"]!!)
		for (i in WSC.readInstructions(script, "A002_01")) {
			println(i)
		}
	}
}