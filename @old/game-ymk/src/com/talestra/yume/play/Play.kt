package com.talestra.yume.play

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.color.Colors
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.ui.image

object Play {
	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val icon = ResourcesVfs["patcher_ico.png"].readBitmap()
		val bb = Bitmap32(640, 480).apply {
			fill(Colors.BLACK)
		}
		Application().frame("YMK", icon = icon) {
			image(bb)
		}
	}
}