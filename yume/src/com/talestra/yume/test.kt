package com.talestra.yume

import com.talestra.rhcommon.io.invoke
import com.talestra.yume.formats.ArcPackage
import java.io.File

fun main(args: Array<String>) {
	val BASE = File("d:/juegos/yume")
	val CHIP = ArcPackage(ARC(BASE["Chip.arc"]))
	val CHIP_OUT = BASE["chip.arc.d"]

	File("D:/BG_IMG13.WIP").writeBytes(CHIP.files["BG_IMG13.WIP"]!!.readAll())

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