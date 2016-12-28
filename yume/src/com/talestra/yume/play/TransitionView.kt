package com.talestra.yume.play

class TransitionView(
	val g: G2
) : View() {
	var step = 0.0

	enum class Type {
		ALPHA,
		MASK,
		MASK_REVERSE
	}

	var transitionType = Type.ALPHA

	var hasMask = false
	val maskBmp = Bitmap32(800, 600)
	val maskTex = g.createTexture(maskBmp)

	val backBmp = Bitmap32(800, 600)
	val backTex = g.createTexture(backBmp)

	val frontBmp = Bitmap32(800, 600)
	val frontTex = g.createTexture(frontBmp)

	fun setMask(mask: Bitmap32) {
		hasMask = true
		this.maskBmp.put(mask)
		maskTex.base.update(maskBmp)
	}

	fun drawBack(view: View) {
		g.renderToBitmap32(backBmp, linear = true) {
			view.render(g)
		}
		//var hash = 0
		//var hashR = 0
		//var hashG = 0
		//var hashB = 0
		//var hashA = 0
		//for (n in 0 until backBmp.data.size) {
		//	val col = backBmp.data[n]
		//	hash += backBmp.data[n]
		//	hashR += RGBA.getR(col)
		//	hashG += RGBA.getG(col)
		//	hashB += RGBA.getB(col)
		//	hashA += RGBA.getA(col)
		//}
		//println("drawBack: $hash, $hashR, $hashG, $hashB, $hashA")
		// drawBack: -346224855, 109587241, 102253276, 103206034, 122400000
		// drawBack: -346224855, 109587241, 102253276, 103206034, 122400000
		backTex.base.update(backBmp)
	}

	fun invert() {
		backBmp.invert()
		backTex.base.update(backBmp)
	}

	fun copyBackToFront() {
		frontBmp.put(backBmp)
		frontTex.base.update(frontBmp)
	}

	override fun renderInternal(g: G2) {
		val step = Mathf.clamp(this.step, 0.0, 1.0)

		if (step < 1.0) {
			g.drawImage(frontTex)
		}

		if (step >= 1.0) {
			g.drawImage(backTex)
		} else if (step > 0.0) {
			when (transitionType) {
				Type.ALPHA -> {
					g.keep {
						g.multiplyColor(1f, 1f, 1f, step.toFloat())
						g.drawImage(backTex)
					}
				}
				Type.MASK, Type.MASK_REVERSE -> {
					if (hasMask) {
						MaskRender.render(g as G2overG3, maskTex, displacement = Mathf.transform01(step, -1.0, +1.0), reverse = transitionType == Type.MASK_REVERSE) { g ->
							g.drawImage(backTex)
						}
					} else {
						g.keep {
							g.multiplyColor(1f, 1f, 1f, step.toFloat())
							g.drawImage(backTex)
						}
					}
				}
			}
		}
	}
}