package com.talestra.yume

import com.soywiz.korio.async.sync
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.LocalVfs
import com.talestra.yume.formats.ArcPackage
import com.talestra.yume.formats.openAsARC

fun main(args: Array<String>) = syncTest {
	val BASE = LocalVfs("d:/juegos/yume")
	val CHIP = ArcPackage(BASE["Chip.arc"].openAsARC())
	val CHIP_OUT = BASE["chip.arc.d"]

	LocalVfs("D:/BG_IMG13.WIP").writeFile(CHIP.files["BG_IMG13.WIP"])

	//CHIP_OUT.mkdirs()
	//for ((name, data) in CHIP.files) {
	//	val basename = File(name).nameWithoutExtension
	//	if (name.endsWith("WIP")) {
	//		for ((index, e) in CHIP.getImage(basename).withIndex()) {
	//			println("$name@$index: $e")
	//			CHIP_OUT["$basename@$index.png"] = PNG.encode(e.bitmap)
	//		}
	//	}
	//	//println("$name:$data")
	//}
	//val wip = WIP.read(CHIP["EV36C.WIP"]!!)

	//CHIP_OUT["EV36C.png"] = PNG.encode(CHIP.getImage("EV36C")[0].bitmap)


	//showImage(CHIP.getImage("EV05AS")[0].bitmap)
	//showImage((WIP.read(CHIP["BLOG.MSK"]!!)[0].bitmap as Bitmap8).setWhitescalePalette())
}