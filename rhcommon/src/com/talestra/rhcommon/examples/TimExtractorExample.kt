package com.talestra.rhcommon.examples

import com.soywiz.kimage.format.PNG
import com.soywiz.korio.stream.openSync
import com.talestra.rhcommon.imaging.format.TIM
import java.io.File

fun main(args: Array<String>) {
	for (file in File("C:/temp").listFiles()) {
		if (file.name.endsWith(".u")) {
			val bytes = file.readBytes()
			if (bytes[0].toInt() == 0x10) {
				File("C:/temp/tim/${file.name}.png").writeBytes(PNG.encode(TIM.read(bytes.openSync("r")).toBMP32()))
			}
		}
	}
}