import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.AsyncStream
import com.soywiz.korio.stream.readS64_le
import com.soywiz.korio.stream.readStringz
import com.soywiz.korio.stream.slice
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.lang.invalidOp

object PS3FS {
	suspend fun read(s: AsyncStream): VfsFile = asyncFun {
		val magic = s.readStringz(8)
		if (magic != "PS3FS_V1") invalidOp("Not a PS3FS_V1")
		val count = s.readS64_le()
		val out = hashMapOf<String, AsyncStream>()
		for (n in 0 until count) {
			val name = s.readStringz(0x30)
			val length = s.readS64_le()
			val offset = s.readS64_le()
			//println("$name: $offset, $length")
			val data = s.slice(offset until offset + length)
			out[name] = data
			//File("c:/temp/crim/$name").writeBytes(data.readAll())
		}
		MemoryVfs(out)
	}
}