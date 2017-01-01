package com.talestra.yume.patcher

import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.ui.button
import com.soywiz.korui.ui.image

object YumeMiruPatcher2 {
	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val bmp = ResourcesVfs["data/bg.jpg"].readBitmap()
		Application().frame("Yume Miru Kusuri en español - $VERSION", 640, 480) {
			image(bmp)
			button("Patch") {
				alert("Patching!")
			}
		}
	}
}
