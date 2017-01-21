package com.talestra.dividead.util

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.dividead.LZ
import com.talestra.dividead.openAsDL1

fun main(args: Array<String>) = sync {
	val dividead = LocalVfs("D:/juegos/dividead")
	extractAll(dividead["WV.DL1"], dividead["WV.DL1.d"])
	extractAll(dividead["SG.DL1"], dividead["SG.DL1.d"])
}

suspend fun extractAll(file: VfsFile, out: VfsFile) {
	out.mkdirs()
	for (file in file.openAsDL1().listRecursive()) {
		val outFile = out[file.path]
		if (!outFile.exists()) {
			val content = file.read()
			val uncompressed = if (LZ.isCompressed(content)) LZ.uncompress(content) else content
			outFile.write(uncompressed)
		}
	}
}