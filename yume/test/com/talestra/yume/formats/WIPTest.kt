package com.talestra.yume.formats

import WIP
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert.assertArrayEquals
import org.junit.Test

class WIPTest {
    @Test
    fun name() = sync {
        val images = WIP.read(ResourcesVfs["BG_IMG13.WIP"].readAsSyncStream())
        val recompressed = WIP.write(images)
        val images2 = WIP.read(recompressed.openSync())
        assertArrayEquals(
                (images[0].bitmap as Bitmap32).data,
                (images2[0].bitmap as Bitmap32).data
        )
    }
}