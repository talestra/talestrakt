package com.talestra.yume.formats

import com.soywiz.korio.async.map
import com.soywiz.korio.async.sync
import com.soywiz.korio.async.toList
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.toAsync
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.io.generate
import org.junit.Assert
import org.junit.Before
import org.junit.Test

class ARCTest {
	lateinit var RIO_ARC: ByteArray
	lateinit var TITLE_WSC_decrypt: ByteArray
	lateinit var rio: VfsFile

	@Before
	fun setUp() = sync {
		val resources = ResourcesVfs
		RIO_ARC = resources["Rio.arc"].read()
		TITLE_WSC_decrypt = resources["TITLE.WSC.decrypt"].read()
		rio = RIO_ARC.openSync().toAsync().openAsARC()
	}

	@Test
	fun testReadAndGenerateArc() = sync {
		val original = RIO_ARC
		val arc = original.openSync("r").toAsync().openAsARC()
		val files = arc.listRecursive().toList()
		val generated = ARC.generate(arc)
		Assert.assertArrayEquals(original, generated)
		Assert.assertEquals(164, files.size)
		Assert.assertEquals(listOf("A002_01.WSC", "A002_02.WSC", "A002_03A.WSC", "A002_03B.WSC", "A002_04.WSC"), files.take(5).map { it.basename })
	}

	@Test
	fun testReadScript() = sync {
		val generated = WSC.Encryption.decrypt(rio["TITLE.WSC"].read())
		Assert.assertArrayEquals(TITLE_WSC_decrypt, generated)
	}

	@Test
	fun testParseScript() = sync {
		val script = WSC.Encryption.decryptStream2(rio["A002_01.WSC"].read().openSync())
		for (i in WSC.readInstructions(script, "A002_01")) {
			println(i)
		}
	}
}