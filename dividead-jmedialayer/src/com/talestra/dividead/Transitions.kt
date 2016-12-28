package com.talestra.dividead

import jmedialayer.graphics.Bitmap32

class Transitions(val screen: Screen) {
	fun transition(kind: Int, step: Double) {
		//when (kind) {
		//	-1, 0 -> dst.copyPixels(src, 0, 0, src.width, src.height, 0, 0)
		//	1, -10 -> transitionPersianaArribaAbajo(src, dst, step)
		//	-2, 2 -> transitionBarridoPersonajeHorizontal(src, dst, step)
		//	3 -> transitionPersianaArribaAbajoAbajoArriba(src, dst, step)
		//	-3, 4 -> transitionBarridoTituloVertical(src, dst, step)
		//	else -> dst.copyPixels(src, 0, 0, src.width, src.height, 0, 0)
		//}
		transitionPersianaArribaAbajoAbajoArriba(step)
	}

	fun transitionPersianaArribaAbajo(step: Double) {
		//val SCREEN_HEIGHT = dst.height
		//int y2;
		//val m = 0;
		//val steps = SCREEN_HEIGHT * 2 / 16;
		//for (n in 0 until steps) {
		//	_UPDATE_RECT_START();
		//	for (y = 0, y2 = n; y <= SCREEN_HEIGHT; y += 16, y2--) {
		//		if (y2 < 0) break;
		//		if (y2 >= 16) continue;
		//		SDL_Rect r = { 0, y - y2, SCREEN_WIDTH, 1 };
		//		_UPDATE_RECT(r);
		//	}
		//	_UPDATE_RECT_END();
		//	PROGRAM_DELAY(1000 / steps);
		//}
	}

	fun transitionBarridoPersonajeHorizontal(step: Double) {
		//steps = 16;
		//for (m = 0; m < 16; m++) {
		//	_UPDATE_RECT_START();
		//	for (n = 0; n < SCREEN_WIDTH; n += 16) {
		//	SDL_Rect r = { n + m, 0, 1, SCREEN_HEIGHT };
		//	_UPDATE_RECT(r);
		//}
		//	_UPDATE_RECT_END();
		//	PROGRAM_DELAY(100 / steps);
		//}
	}

	fun transitionPersianaArribaAbajoAbajoArriba(step: Double) {
		for (n in 0 until (screen.height / 2 * step).toInt()) {
			val n2 = n * 2
			screen.copyRow(n2)
			screen.copyRow(screen.height - n2 - 1)
		}
	}

	fun transitionBarridoTituloVertical(src: Bitmap32, dst: Bitmap32, step: Double) {
		//steps = 16;
		//for (m = 0; m < 16; m++) {
		//	_UPDATE_RECT_START();
		//	for (n = 0; n < SCREEN_HEIGHT; n += 16) {
		//	SDL_Rect r = { 0, n + m, SCREEN_WIDTH, 1 };
		//	_UPDATE_RECT(r);
		//}
		//	_UPDATE_RECT_END();
		//	PROGRAM_DELAY(100 / steps);
		//}
	}
}