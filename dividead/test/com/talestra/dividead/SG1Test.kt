package com.talestra.dividead

class SG1Test {
	companion object {
		val TEST_DL1 = ClassLoader.getSystemResource("TEST.DL1").readBytes()
	}

	//@Test
	//fun name() {
	//	val files = DL1.read(TEST_DL1.open2("r"))
	//	val generated = DL1.generate(files)
	//	Assert.assertArrayEquals(TEST_DL1, generated)
//
	//	Assert.assertEquals(
	//		listOf(
	//			"(B.TXT, SliceStream2(parent=MemoryStream2(86), start=16, end=21))",
	//			"(HELLO.TXT, SliceStream2(parent=MemoryStream2(86), start=21, end=33))",
	//			"(A.TXT, SliceStream2(parent=MemoryStream2(86), start=33, end=38))"
	//		),
	//		files.toList().map { it.toString() }
	//	)
	//}
//
	//@Test
	//fun testDecompression() {
	//	val files = DL1.read(File("D:/juegos/dividead/SG.DL1").open2("r"))
	//	val uncompressedData = LZ.uncompress(files["OMAKE_3.BMP"]!!.readAll())
	//	File("D:/juegos/dividead/OMAKE_3.BMP").writeBytes(uncompressedData)
	//}
}