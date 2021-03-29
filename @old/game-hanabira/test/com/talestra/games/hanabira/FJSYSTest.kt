package com.talestra.games.hanabira

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.async.toList
import com.soywiz.korio.util.readStringz
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class FJSYSTest {
	@Test
	fun name() = syncTest {
		val root = ResourcesVfs["MSE"].openFJSYS()

		Assert.assertEquals(
				"CGLIST.MSD,CGView.MSD,CONF.MSD,main.MSD,MESWND.MSD,OMAKE.MSD,OPTION.MSD,S001.MSD,S002.MSD,S003.MSD,S004.MSD,S005.MSD,S006.MSD,S007.MSD,S008.MSD,S009.MSD,S010.MSD,S011.MSD,S012.MSD,S013.MSD,S014.MSD,S015.MSD,SAVELOAD.MSD,SCENELIST.MSD,STAFF.MSD,start.MSD,TITLE.MSD",
				root.list().toList().map { it.basename }.joinToString(",")
		)


		Assert.assertEquals(
				"MSCENARIO FILE  ",
				MSD.decrypt(root["CGLIST.MSD2"].read()).readStringz(0, 0x10)
		)
	}
}