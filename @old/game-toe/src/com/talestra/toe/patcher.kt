package com.talestra.toe

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.openAsIso
import com.talestra.talesof.complib.OldCompTalesOfLLib.Decode
import java.io.File

fun main(args: Array<String>) = syncTest {
	val ISO_FILE = LocalVfs("d:/isos/psp/toe.iso")
	val root = ISO_FILE.openAsIso()
	val temp = ByteArray(5 * 1024 * 1024)
	val files = PakBDPair.parseB_DPair(
			root["PSP_GAME/USRDIR/dat/m_us.b"].open(),
			root["PSP_GAME/USRDIR/dat/m_us.d"].open()
	)
	for (file in files.listRecursive()) {
		val index = file.basename.toInt()
		val file = file.open()
		println("$index, $file")
		File("C:/temp/$index.bin").writeBytes(file.slice().readAll())
		for (sfile in PakBDPair.parseDFile(file.slice()).listRecursive()) {
			val subindex = sfile.basename.toInt()
			val subfile = sfile.open()
			val subcontent = subfile.readAll()
			File("C:/temp/$index@$subindex.bin").writeBytes(subcontent)
			if (subcontent[0].toInt() == 3) {
				val ss = subcontent.openSync()
				val version = ss.readU8()
				val compressed = ss.readS32_le()
				val uncompressed = ss.readS32_le()
				val compressedData = ss.readBytes(compressed)
				//println(compressed)
				//println(uncompressed)
				//println("---")
				Decode(version, compressedData, compressed, temp, uncompressed)
				//println(uncompressed)
				File("C:/temp/$index@$subindex.bin.u").writeBytes(temp.copyOf(uncompressed))
			}
		}
	}
}

