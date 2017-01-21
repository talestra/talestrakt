package com.talestra.platform.n3ds

import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.invalidOp

// https://www.3dbrew.org/wiki/RomFS
object N3dsRomFS {
	suspend fun read(s: AsyncStream) {
		val h = s.readBytes(0x60).openSync()
		if (h.readStringz(4) != "IVFC") invalidOp("Not a RomFS")
		if (h.readS32_le() != 0x10000) invalidOp("Not a RomFS (II)")
		val masterHashSize = h.readS32_le()
		val level1LogicalOffset = h.readS64_le()
		val level1HashDataSize = h.readS64_le()
		val level1BlockSize = h.readS32_le()
		val resv1 = h.readS32_le()
		val level2LogicalOffset = h.readS64_le()
		val level2HashDataSize = h.readS64_le()
		val level2BlockSize = h.readS32_le()
		val resv2 = h.readS32_le()
		val level3LogicalOffset = h.readS64_le()
		val level3HashDataSize = h.readS64_le()
		val level3BlockSize = h.readS32_le()
		val resv3 = h.readS32_le()
		val resv4 = h.readS32_le()
		val optInfoSize = h.readS32_le()
		val resv5 = h.readS32_le()
		val masterHash = h.readBytes(masterHashSize)

		println("%08X, %08X".format(masterHashSize, optInfoSize))
		println("%08X, %08X, %08X".format(level1LogicalOffset, level1HashDataSize, level1BlockSize))
		println("%08X, %08X, %08X".format(level2LogicalOffset, level2HashDataSize, level2BlockSize))
		println("%08X, %08X, %08X".format(level3LogicalOffset, level3HashDataSize, level3BlockSize))
	}
}