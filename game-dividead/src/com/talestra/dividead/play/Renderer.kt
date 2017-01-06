package com.talestra.dividead.play

import com.soywiz.korim.geom.Anchor

open class Renderer {
	suspend open fun draw(img: String, x: Int = 0, y: Int = 0, anchor: Anchor = Anchor.TOP_LEFT) {
	}

	suspend open fun fill(x: Int, y: Int, width: Int, height: Int, color: Int) {
	}

	suspend open fun text(text: String, x: Int = 0, y: Int = 0) {
	}

	suspend open fun update(x: Int, y: Int, width: Int, height: Int) {
	}

	suspend open fun playMusic(s: String) {
	}

	suspend open fun drawMasked(color: String, mask: String, x: Int, y: Int, anchor: Anchor) {
	}
}