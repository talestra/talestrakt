package com.talestra.dividead.util

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.color.RGBA
import org.jcodec.api.FrameGrab
import java.io.File

fun main(args: Array<String>) {
	val frameNumber = 50
	val frame = FrameGrab.getNativeFrame(File("D:/juegos/dividead/CS_ROGO.AVI.2x.mp4"), frameNumber)
	//val frame = FrameGrab.getNativeFrame(File("D:/juegos/dividead/CS_ROGO.AVI"), frameNumber)
	//val frame = FrameGrab.getNativeFrame(File("D:/juegos/yume/A_ED.dat"), frameNumber)
	val plane = frame.getPlaneData(0)

	val bmp = Bitmap32(frame.width, frame.height)

	for (n in 0 until frame.width * frame.height) {
		//val r = frame.data[0][n]
		//val g = frame.data[1][n]
		//val b = frame.data[2][n]
		//bmp.data[n] = RGBA.pack(r, g, b, 0xFF)
		bmp.data[n] = RGBA.packRGB_A(plane[n], 0xFF)
	}
	//println(frame.data)
	//Bitmap32(frame.width, frame.height, frame.data)
	//frame.
	//ImageIO.write(frame, "png", File("frame_150.png"))
	awtShowImage(bmp)

}