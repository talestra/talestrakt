package com.talestra.yume.play

/*
class YumeIngameUi(
	val g2: G2,
	font: BitmapFont
) : ViewContainer() {
	val BORDER_COLOR = RGBA(0x3c, 0x5F, 0xAF, 0xFF)

	val titleText = Text(font, "", size = 24.0).apply {
		border = true
		borderColor = BORDER_COLOR
		setXY(48.0, 10.0)
		bold = true
		scaleX = 0.75
		lineSpacing = 1.2
	}
	val bodyText = Text(font, "", size = 24.0).apply {
		border = true
		borderColor = BORDER_COLOR
		setXY(64.0, 66.0)
		bold = true
		scaleX = 0.75
		lineSpacing = 1.2
	}

	var uibg = WipView(g2, listOf())
	var uiBgContainer = ViewContainer().apply {
		this += uibg
	}

	init {
		children += uiBgContainer
		children += titleText
		children += bodyText
	}

	fun setText(body: String, title: String) {
		titleText.text = title
		bodyText.text = body
		uibg.images.getOrNull(25)?.visible = title.isNotEmpty()
	}

	fun setWIP(view: WipView) {
		uibg = view
		uiBgContainer.removeChildren()
		uiBgContainer += uibg
	}

	fun setTextSize(size: Int) {
	}
}
	*/