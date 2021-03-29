package com.talestra.yume.util

import com.soywiz.korio.async.sync
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.LocalVfs
import com.talestra.yume.formats.WSC
import com.talestra.yume.formats.openAsARC
import java.io.File

fun main(args: Array<String>) = syncTest {
	val base = LocalVfs("D:/juegos/yume")
	for (file in listOf(base["CHIP.ARC"], base["BGM.ARC"], base["RIO.ARC"], base["VOICE.ARC"], base["SE.ARC"])) {
		val out = file.parent["${file.basename}.d"]
		out.mkdirs()
		println("ARC: $file")
		for (file in file.openAsARC().listRecursive()) {
			val name = file.fullname
			println("$name")
			//if (out[name].exists()) continue
			val bytes = file.read()
			out.set(name, bytes)
			if (name.endsWith("WSC")) {
				out.set(File(name).nameWithoutExtension + ".WS", WSC.Encryption.decrypt(bytes))
			}
		}
		/*
		ARC.read(file.open2("r"))
		val arc = ARC.readAsync(file.openAsync2().await()).await()
		//println(arc)
		for (stat in arc.listAsync().toListAsync().await()) {
			println(stat)
		}
		*/
		//arc.listAsync().eachAsync { stat ->
		//	println(stat.file)
		//}.await()
	}
}