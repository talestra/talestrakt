package com.talestra.criminalgirls

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.format.PNG
import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsOpenMode
import com.soywiz.korio.vfs.open
import com.talestra.rhcommon.lang.indexOf
import com.talestra.rhcommon.lang.toHexString
import java.io.File
import java.nio.charset.Charset

fun main(args: Array<String>) = sync {
	translateTest()
	//return com.talestra.criminalgirls.decodeTest()
	//return com.talestra.criminalgirls.encodeTest()
	//return com.talestra.criminalgirls.dumpTest()
}

fun decodeTest() {
	val png = PNG().decode(File("c:/temp/crim/tomoe1.imy.png"))
	awtShowImage(png)
}

fun encodeTest() {
	val out = IMY.decode(File("c:/temp/crim/title.0001.imy"))
	awtShowImage(out)
	val reencoded = IMY.encode(out)
	File("c:/temp/crim/title.0001.imy.8.png").writeBytes(PNG().encode(out))
	File("c:/temp/crim/title.0001.imy.rec").writeBytes(reencoded)
	val redecoded = IMY.decode(reencoded)
	awtShowImage(redecoded)

	return
}

suspend fun translateTest() {
	val mod = LocalVfs("D:/isos/psvita/DATA.DAT")
	val ori = LocalVfs("D:/isos/psvita/DATA.DAT.ori")

	if (!ori.exists()) {
		mod.copyTo(ori)
	}

	Translation.translate(mod.open())
}

fun dumpTest() = sync {
	val mod = File("D:/isos/psvita/DATA.DAT")
	val files = PS3FS.read(mod.open(VfsOpenMode.READ))
	val parent = LocalVfs("c:/temp/crim")

	for (file in files.listRecursive()) {
		val name = file.basename
		println("$file")
		val f = parent[name]
		if (!f.exists()) {
			parent[name] = file.read()
		}
		if (f.extension == "imy") {
			println(f.path)
			val png = parent[f.path + ".png"]
			if (!png.exists()) {
				//if (true) {
				png.write(PNG().encode(IMY.read(f.read().openSync())))
			}
		}
	}
}

object demo {
	/**
	 * DATA.DAT:
	 * - SHA1: 7F3CDADB530C1AD2100B96CD8235E7A95D76BB11
	 */

	// This produces a don't know how to generate outer expression
	suspend fun extract(s: AsyncStream) {
		for (stat in PS3FS.read(s).listRecursive()) {
			println("${stat.basename}: ${stat.size()}")
		}
		//println(count)
	}

	//extract(File("D:/isos/psvita/DATA.DAT").open2("r"))

	//val parent = File("c:/temp/crim")
	//for (f in parent.listFiles()) {
	//	if (f.extension == "imy") {
	//		println("${f.name}")
	//		val png = File(parent, f.name + ".png")
	//		//if (!png.exists()) {
	//		if (true) {
	//			png.writeBytes(PNG.encode(com.talestra.criminalgirls.IMY.read(f.open2("r")).toBMP32()))
	//		}
	//	}
	//}

	//File("c:/temp/crim/font_00.imy.png").writeBytes(PNG.encode(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/font_00.imy").open2("r")).toBMP32()))

	//val datab = File("c:/temp/1111/hsb.gxt").readBytes().sliceArray(0x40 until 256 * 256 * 4 + 0x40)

	//val datab2 = com.talestra.criminalgirls.PostProcessing.UnswizzleTexture(datab, 256, 256, 32)

	//val data = Bitmap32(256, 256, JTranscArrays.copyReinterpretInt_LE(datab2))

	//showImage(data)

	/*
	val data = Bitmap32(256, 256, JTranscArrays.copyReinterpretInt_LE(File("c:/temp/1111/range.gxt").readBytes().sliceArray(0x40 until 256 * 256 * 4 + 0x40)))
	//val data = Bitmap32(256, 256, JTranscArrays.copyReinterpretInt_LE(File("c:/temp/1111/range.tga").readBytes().sliceArray(0x12 until 256 * 256 * 4 + 0x12)))
	for (y in 0 until 256) {
		for (x in 0 until 256) {
			println("%08X: %d, %d".format(data[x, y], x, y))
		}
	}
	*/
	//return

	//val idata = (0 until 256 * 256).map { n ->
	//	RGBA.pack(
	//		data.getu(n * 4 + 0),
	//		data.getu(n * 4 + 1),
	//		data.getu(n * 4 + 2),
	//		data.getu(n * 4 + 3)
	//	)
//
	//}.toIntArray()
//
	//File("c:/temp/1111/range.tga").open2("rw").apply {
	//	this.position = 0x12
	//	for (n in 0 until 512 * 512) {
	//		this.writeU32_le(n)
	//	}
	//}

	//File("c:/temp/1111/hsb.gxt.png").writeBytes(PNG.encode(Bitmap32(256, 256, idata)))
	//showImage()
	//return

	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/1111/pict06.tpk.imy").open2("r"))) }

	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/nopic.imy").open2("r"))) }
	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/yuko_5_07.imy").open2("r"))) }
	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/alice5.imy").open2("r"))) }
	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/hime4.imy").open2("r"))) }


	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/os_04_00.ptm.imy").open2("r"))) }
	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/os_04_04i.ptm.imy").open2("r"))) }

	//val vfs = com.talestra.criminalgirls.PS3FS.read(mod.open2("r"))

	//val glyphs = com.talestra.criminalgirls.FONT_WIDTHS.writeLines(com.talestra.criminalgirls.FONT_WIDTHS.read(vfs["font.bin"]!!))
	//for (g in glyphs) println(g)

	//return Unit.apply { showImage(com.talestra.criminalgirls.IMY.read(File("c:/temp/crim/font_00.imy").open2("r"))) }

	//com.talestra.criminalgirls.FONT_WIDTHS.read(File("c:/temp/crim/font.bin").open2("r"))

	//return println(File("c:/temp/crim/map_d_000_006.tpk").readBytes().indexOf(byteArrayOf(0xBF.toByte(), 0x64.toByte())))


	//println(com.talestra.criminalgirls.SEARCH.searchFiles(File("c:/temp"), byteArrayOf(0xBF.toByte(), 0x64.toByte())))


	//com.talestra.criminalgirls.SEARCH.searchFiles(File("c:/temp/crim"), "New Game")
	//com.talestra.criminalgirls.SEARCH.searchFiles(File("c:/temp/crim"), "I hear a woman's voice")


	//val bmp = com.talestra.criminalgirls.IMY.read(File("C:\\temp\\crim\\font_00.imy").readBytes().open2("r"))
	//val IMYEncoded = com.talestra.criminalgirls.IMY.encode(bmp)
	//File("C:\\temp\\crim\\font_00.imy2").writeBytes(IMYEncoded)
	//showImage(com.talestra.criminalgirls.IMY.read(IMYEncoded.open2("r")))
	//return


	/*
	val script = com.talestra.criminalgirls.BSCR.read(com.talestra.criminalgirls.DSARCIDX.read(File("c:/temp/crim/map_d_005_001.tpk").open2("r")).values.first())
	for (f in script.funcs) {
		for ((n, i) in f.ins.withIndex()) {
			if (i is com.talestra.criminalgirls.BSCR.II.PushString && i.str != " ") {
				println("${script.name}@${f.name}@$n:\"${i.str.escape()}\"")
			}
		}
	}
	*/

	//File("c:/temp/crim/map_d_000_006.bms.new").writeBytes(script.gen())

//	com.talestra.criminalgirls.BSCR.read(com.talestra.criminalgirls.DSARCIDX.read(File("c:/temp/crim/map_d_000_005.tpk").open2("r")).values.first())
//	com.talestra.criminalgirls.BSCR.read(com.talestra.criminalgirls.DSARCIDX.read(File("c:/temp/crim/map_d_000_004.tpk").open2("r")).values.first())

	//com.talestra.criminalgirls.DSARCIDX.read(File("c:/temp/crim/btl_char_08_1.tpk").open2("r"))

	fun start() {

	}
}

object SEARCH {
	fun searchFiles(path: File, data: ByteArray, text: String = data.toHexString()) {
		for (file in path.listFiles()) {
			if (!file.isFile) continue
			//println(file)

			val index = file.readBytes().indexOf(data)
			if (index >= 0) {
				println("$file contains '$text' at $index")
			}
		}
	}

	fun searchFiles(path: File, text: String, charset: Charset = Charsets.UTF_8) {
		val data = text.toByteArray(charset)
		searchFiles(path, data, text)
	}
}
