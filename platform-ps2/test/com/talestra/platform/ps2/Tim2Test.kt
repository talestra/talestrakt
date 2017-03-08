package com.talestra.platform.ps2

import com.soywiz.korim.awt.awtShowImageAndWait
import com.soywiz.korim.format.readImageFramesNoNative
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test
import java.awt.BorderLayout
import java.awt.image.BufferedImage
import javax.swing.ImageIcon
import javax.swing.JFrame
import javax.swing.JLabel

class Tim2Test {
	@Test
	fun name(): Unit = syncTest {
		//val frames = ResourcesVfs["PK_ETC.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["_FONTB.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["_S_MENU.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["S_TOA_LOGO.TM2"].readImageFramesNoNative()
		val frames = ResourcesVfs["S_DB_SECRET.TM2"].readImageFramesNoNative()
		for (frame in frames) {
			awtShowImageAndWait(frame.bitmap)
		}
		Unit
	}
}

fun awtShowImage(image: BufferedImage): JFrame {
	println("Showing: $image")
	val frame = object : JFrame("Image (${image.width}x${image.height})") {

	}
	val label = JLabel()
	label.icon = ImageIcon(image)
	label.setSize(image.width, image.height)
	frame.add(label, BorderLayout.CENTER)
	//frame.setSize(bitmap.width, bitmap.height)
	frame.defaultCloseOperation = JFrame.DISPOSE_ON_CLOSE
	frame.pack()
	frame.setLocationRelativeTo(null)
	frame.isVisible = true
	return frame
}
