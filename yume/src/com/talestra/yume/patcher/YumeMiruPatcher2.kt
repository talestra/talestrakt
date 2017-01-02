package com.talestra.yume.patcher

import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.ui.button
import com.soywiz.korui.ui.image
import com.soywiz.korui.ui.vertical

object YumeMiruPatcher2 {
	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val bmp = ResourcesVfs["data/bg.jpg"].readBitmap()
		val frameIcon = ResourcesVfs["patcher_ico.png"].readBitmap()
		Application().frame("Yume Miru Kusuri en español - $VERSION", 640, 480) {
			icon = frameIcon
			image(bmp)
			vertical {
				button("Patch") {
					alert("Patching!")
				}
			}
		}
	}
}
