package com.talestra.platform.n3ds

import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.sliceWithStart
import com.soywiz.korio.vfs.LocalVfs
import org.junit.Test

class TestRomFS {
	val testFile = LocalVfs("D:/isos/3ds/CTR-P-AABP-dec.3ds")
	@Test
	fun name() = sync {
		/*
		ctrtool -p --exheader=DecryptedExHeader.bin %Name%.3ds
		ctrtool -p --exefs=DecryptedExeFS.bin %Name%.3ds
		ctrtool -p --romfs=DecryptedRomFS.bin %Name%.3ds

		ctrtool.exe -t romfs --romfsdir=./romfs DecryptedRomFS.bin
		ctrtool.exe -t exefs --exefsdir=./exe DecryptedExeFS.bin --decompresscode
 		 */
		val slice = testFile.open().sliceWithStart(0x0026C800L)
		N3dsRomFS.read(slice)
	}
}