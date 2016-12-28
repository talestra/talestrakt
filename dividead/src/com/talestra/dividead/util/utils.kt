package com.talestra.dividead.util

import com.talestra.dividead.DL1
import com.talestra.dividead.LZ
import java.io.File

fun main(args: Array<String>) {
	extractAll(File("D:/juegos/dividead/WV.DL1").open2("r"), File("D:/juegos/dividead/WV.DL1.d"))
	extractAll(File("D:/juegos/dividead/SG.DL1").open2("r"), File("D:/juegos/dividead/SG.DL1.d"))
}

fun extractAll(file: Stream2, out: File) {
	out.mkdirs()
	for ((name, data) in DL1.read(file.slice())) {
		val outFile = File(out, name)
		if (!outFile.exists()) {
			val content = data.readAll()
			val uncompressed = if (LZ.isCompressed(content)) LZ.uncompress(content) else content
			outFile.writeBytes(uncompressed)
		}
	}
}