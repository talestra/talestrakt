package com.talestra.yume.play

import WIP

class WipView(val g2: G2, val entries: List<WIP.Entry>) : ViewContainer(), Disposable {
	constructor(g2: G2, wipData: ByteArray) : this(g2, WIP.read(wipData.open2("r")))

	val images = entries.map { entry -> Image(g2.createTexture(entry.bitmap)).apply { x = entry.x.toDouble(); y = entry.y.toDouble() } }

	init {
		this += images
	}

	override fun dispose() {
		for (i in images) i.texture.dispose()
	}
}
