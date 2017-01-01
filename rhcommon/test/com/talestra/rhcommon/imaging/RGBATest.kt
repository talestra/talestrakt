package com.talestra.rhcommon.imaging

import com.soywiz.korim.color.RGBA
import org.junit.Assert.assertEquals
import org.junit.Test

class RGBATest {
    @Test
    fun name() {
        assertEquals(0, RGBA.clamp0_FF(Int.MIN_VALUE))
        assertEquals(0, RGBA.clamp0_FF(-999))
        for (n in 0 until 0x100) assertEquals(n, RGBA.clamp0_FF(n))
        assertEquals(255, RGBA.clamp0_FF(256))
        assertEquals(255, RGBA.clamp0_FF(1000))
        assertEquals(255, RGBA.clamp0_FF(Int.MAX_VALUE))
    }
}