package com.talestra.tod

/*
class Progress {
	private var text: String? = null;
	var minValue: Int = 0;
	var running  = false;
	var finished = false;

	var startTime: d_time? = null
	var actuallyElapsedTime: Long = 0L;
	var initiallyExpectedTotalTime: Long = 0L
	var currentlyExpectedTotalTime: Long = 0L
	var initiallyExpectedCurrentTime: Long = 0L
	var expectedLastStepTime: Long = 0L

	fun getText(): String {
		if (finished) return "¡Terminado!";
		if (!running || !text.length) return "Esperando...";
		return text
	}

	fun init() {
		startTime = getUTCtime();
		minValue = 0;
		initiallyExpectedCurrentTime = 0;
		expectedLastStepTime = 0;
	}

	fun setTotalTime(totalTime: Long) {
		currentlyExpectedTotalTime = initiallyExpectedTotalTime = totalTime;
		init();
	}

	fun updateCurrentElapsed(): Long {
		return actuallyElapsedTime = getUTCtime() - startTime;
	}

	fun setGlobalStep(expectedTime: Long, text: String? = null): Unit {
		this.text = text;
		initiallyExpectedCurrentTime += expectedLastStepTime;
		expectedLastStepTime = expectedTime;

		updateCurrentElapsed();
		if (initiallyExpectedCurrentTime != 0) {
			val per = initiallyExpectedCurrentTime.toDouble() / initiallyExpectedTotalTime.toDouble()
			//currentlyExpectedTotalTime = initiallyExpectedTotalTime * initiallyExpectedCurrentTime / actuallyElapsedTime;
			currentlyExpectedTotalTime = initiallyExpectedTotalTime * actuallyElapsedTime / initiallyExpectedCurrentTime;
			currentlyExpectedTotalTime = (currentlyExpectedTotalTime * per + initiallyExpectedTotalTime * (1 - per))
		}
	}

	fun getProgress(TOTAL: Int): Int {
		if (finished) return TOTAL;
		if (!running) return 0;

		updateCurrentElapsed();

		if (currentlyExpectedTotalTime == 0L) return 0;
		var retval: Int = (actuallyElapsedTime * TOTAL / currentlyExpectedTotalTime).toInt()

		if (retval < 0) retval = 0;
		if (retval > TOTAL) retval = TOTAL
		if (retval < minValue) retval = minValue; else minValue = retval;
		return retval;
	}
}
*/
