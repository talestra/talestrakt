package com.talestra.platform.ps2

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.awt.toAwt
import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.format.readBitmap
import com.soywiz.korim.format.readImageFramesNoNative
import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test
import java.awt.BorderLayout
import java.awt.event.WindowAdapter
import java.awt.event.WindowEvent
import java.awt.image.BufferedImage
import javax.swing.ImageIcon
import javax.swing.JFrame
import javax.swing.JLabel
import kotlin.coroutines.suspendCoroutine

class Tim2Test {
	@Test
	fun name(): Unit = sync {
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

suspend fun awtShowImageAndWait(image: Bitmap): Unit = awtShowImageAndWait(image.toBMP32().toAwt())

suspend fun awtShowImageAndWait(image: BufferedImage): Unit = suspendCoroutine { c ->
	awtShowImage(image).addWindowListener(object : WindowAdapter() {
		override fun windowClosing(e: WindowEvent) {
			c.resume(Unit)
		}
	})
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
