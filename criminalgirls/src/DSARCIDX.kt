import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.lang.invalidOp
import java.util.*

object DSARCIDX {
	suspend fun read(s: AsyncStream): VfsFile = asyncFun {
		val magic = s.readStringz(8)
		if (magic != "DSARCIDX") invalidOp("Not a DSARCIDX file, but '$magic'")
		val count = s.readS64_le()
		s.readShortArray_le(count.toInt())
		while (s.getPosition() % 4L != 0L) {
			val ff = s.readU8()
			if (ff != 0xff) invalidOp("Expected 0xFF for padding")
		}
		val sh = s.readBytes((0x28 + 4 + 4) * count.toInt()).openSync("r")
		val out = LinkedHashMap<String, AsyncStream>()
		for (n in 0 until count) {
			val name = sh.readStringz(0x28)
			val length = sh.readS32_le()
			val start = sh.readS32_le()
			out[name] = s.slice(start until start + length)
			//println("$name: $start..$length")
		}
		MemoryVfs(out)
	}
}

suspend fun AsyncStream.openAsDsarCidx() = DSARCIDX.read(this)
suspend fun VfsFile.openAsDsarCidx() = asyncFun { DSARCIDX.read(this.open()) }