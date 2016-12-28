package com.talestra.shny

import com.talestra.rhcommon.imaging.format.GIM
import java.io.File

fun main(args: Array<String>) {
	EventLoop.mainAsync {
		val iso = File("D:/isos/console/psp/Suzumiya Haruhi no Yakusoku.iso")
		val files = ISO.openVfsAsync(iso.openAsync2().await()).await()

		//val data = files["PSP_GAME/USRDIR/data/script/s_tnormal.dat"].open2("r").readAll()
		//val s = data.open2("r")
		//Script.check(s)
		//s.position = 8
		//while (!s.eof) Script.readInstruction(s)

		for (file in files["PSP_GAME/USRDIR/data/bg"].listAsync().toListAsync().await()) {
			val img = GIM.read(file.file.readStreamAsync().await())
			File("D:/bg/${file.name}.png").writeBytes(PNG.encode(img.toBMP32()))
		}

		//val gim = GIM.read(files["PSP_GAME/USRDIR/data/bg/bg001_0.gim"].open2("r"))
		//showImage(gim)
	}
}