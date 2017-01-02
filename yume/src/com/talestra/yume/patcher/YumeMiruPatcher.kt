package com.talestra.yume.patcher

import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.geom.len.Padding
import com.soywiz.korui.geom.len.pt
import com.soywiz.korui.style.padding
import com.soywiz.korui.style.width
import com.soywiz.korui.ui.*

object YumeMiruPatcher {
	const val VERSION = "v1.0"

	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val bmp = ResourcesVfs["data/bg.jpg"].readBitmap()
		val frameIcon = ResourcesVfs["patcher_ico.png"].readBitmap()
		Application().frame("Yume Miru Kusuri en español - $VERSION", 640, 480) {
			icon = frameIcon
			vertical {
				image(bmp)
			}
			layers {
				padding = Padding(16.pt)
				vertical {
					padding = Padding(16.pt)
					horizontal {
						padding = Padding(16.pt)
						button("Parchear...") {
							alert("Patching!")
						}.apply {
							width = 200.pt
						}
					}
					horizontal {
						padding = Padding(16.pt)
						button("Página web...") {
							openURL("http://yume.tales-tra.com/")
						}.apply {
							width = 200.pt
						}
					}
				}
			}
		}
	}
}
