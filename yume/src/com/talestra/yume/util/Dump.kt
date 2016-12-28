package com.talestra.yume.util

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsOpenMode
import com.talestra.yume.formats.ARC
import com.talestra.yume.formats.WSC
import java.io.File

fun main(args: Array<String>) = sync {
	val base = LocalVfs("D:/juegos/yume")
	for (file in listOf(base["CHIP.ARC"], base["BGM.ARC"], base["RIO.ARC"], base["VOICE.ARC"], base["SE.ARC"])) {
		val out = file.parent["${file.basename}.d"]
		out.mkdirs()
		println("ARC: $file")
		for ((name, data) in ARC.read(file.open(VfsOpenMode.READ))) {
			println("$name")
			//if (out[name].exists()) continue
			val bytes = data.readAll()
			out[name] = bytes
			if (name.endsWith("WSC")) {
				out[File(name).nameWithoutExtension + ".WS"] = WSC.Encryption.decrypt(bytes)
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