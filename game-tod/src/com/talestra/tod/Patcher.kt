package com.talestra.tod

import com.soywiz.korim.format.readNativeImage
import com.soywiz.korim.geom.Anchor
import com.soywiz.korim.geom.ScaleMode
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.geom.len.*
import com.soywiz.korui.style.height
import com.soywiz.korui.style.minWidth
import com.soywiz.korui.style.padding
import com.soywiz.korui.style.width
import com.soywiz.korui.ui.*
import com.talestra.rhcommon.imaging.format.ICO

object TodPatcher {
	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val resources = ResourcesVfs["com/talestra/tod"]
		val bmp = resources["logo.png"].readNativeImage()
		val icon = ICO.decode(resources["icon.ico"].readAsSyncStream())
		Application().frame("Tales of Destiny en español - v1.0", width = 640, height = 480, icon = icon) {
			padding.setTo(8.pt)
			vertical {
				layersKeepAspectRatio(anchor = Anchor.BOTTOM_RIGHT, scaleMode = ScaleMode.COVER) {
					width = 100.percent
					height = 30.vh
					//image(bmp)
					image(icon)
				}
				//padding.setTo(6.pt)
				label("ISO:")
				horizontal {
					//padding.setTo(6.pt)
					label("Original:") {
						width = 20.percent
						minWidth = 1.cm
					}
					val path = textField() { width = 100.percent }
					button("Elegir...") {
						width = 20.percent
						minWidth = 1.cm
					}.click {
						val file = dialogOpenFile()
						path.text = file.absolutePath
					}
				}
				label("Opciones:")
				inline {
					checkBox("Opening JAP", checked = true)
					checkBox("Modo debug", checked = false)
				}
				label("Información:")
				inline {
					button("Tales Translations").click {
						openURL("http://tales-tra.com/")
					}
					button("Página web...").click {
						openURL("http://tod.tales-tra.com/")
					}
					button("Créditos...")
				}
				label("Traducir:")
				horizontal {
					//label("Versión para traductores y betatesters. NO DISTRIBUIR.") {
					progress(50, 100).apply {
						width = 80.percent
					}
					button("Traducir") {
						width = 20.percent
					}
				}
			}
		}
	}
}