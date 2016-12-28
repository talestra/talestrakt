package com.talestra.toe

import com.talestra.talesof.comlib.Decode
import java.io.File

fun main(args: Array<String>) {
	EventLoop.mainAsync {
		val ISO_FILE = File("d:/isos/psp/toe.iso")
		val root = ISO.openVfsAsync(ISO_FILE.openAsync2().await()).await()
		val temp = ByteArray(5 * 1024 * 1024)
		val files = PakBDPair.parseB_DPair(
			root["PSP_GAME/USRDIR/dat/m_us.b"].readStreamAsync().await(),
			root["PSP_GAME/USRDIR/dat/m_us.d"].readStreamAsync().await()
		)
		for ((index, file) in files.withIndex()) {
			File("C:/temp/$index.bin").writeBytes(file.slice().readAll())
			for ((subindex, subfile) in PakBDPair.parseDFile(file.slice()).withIndex()) {
				val subcontent = subfile.readAll()
				File("C:/temp/$index@$subindex.bin").writeBytes(subcontent)
				if (subcontent[0].toInt() == 3) {
					val ss = subcontent.open2("r")
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
}

