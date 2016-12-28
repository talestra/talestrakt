package com.talestra.rhcommon.imaging.format

import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class TimTest {
	@Test
	fun name() = sync {
		TIM.read(ResourcesVfs()["test.tim"].read().openSync())
	}
}