package com.talestra.dividead.remaster

import com.talestra.dividead.DL1
import com.talestra.dividead.LZ
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

object Remaster {
	val waifu2x_caffe_cui = "C:/projects/waifu2x-caffe/waifu2x-caffe-cui.exe"
	val ffmpeg = "ffmpeg"

	@Throws(java.io.IOException::class)

	fun exec(vararg args: String): Int {
		return ProcessBuilder(*args).start().waitFor()
	}

	fun execStr(vararg args: String): String? {
		val proc = ProcessBuilder(*args).start()
		val out = proc.inputStream.readBytes().toString(Charsets.UTF_8)
		val err = proc.errorStream.readBytes().toString(Charsets.UTF_8)
		val result = proc.waitFor()
		return out + err
	}

	fun passthru(vararg args: String): Int {
		val ps = ProcessBuilder(*args)
		//ps.directory(File(path))
		ps.redirectErrorStream(true)

		val process = ps.start()

		val os = BufferedReader(InputStreamReader(process.inputStream))
		var out = ""

		while (true) {
			val line = os.readLine() ?: break
			out += "$line\n"
			println(line)
		}
		return process.waitFor()
	}

	fun waifu2x(input: File, output: File): Int = exec(
		waifu2x_caffe_cui,
		"--gpu", "0",
		"-s", "2.0",
		"-i", input.absolutePath,
		"-o", output.absolutePath
	)

	fun ffmpegExtractImages(input: File, output: File): Int {
		output.mkdirs()
		return passthru(
			ffmpeg,
			"-y",
			"-i", input.absolutePath,
			"-f", "image2",
			"${output.absolutePath}/%06d.png"
		)
	}

	fun ffmpegExtractAudio(input: File, output: File) = passthru(
		ffmpeg,
		"-y",
		"-i", input.absolutePath,
		output.absolutePath
	)

	/*
	class VideoInfo(
		val fps: Int
	)
	*/

	fun ffmpegGetVideoInfo(input: File) {
		val result = execStr(ffmpeg, "-i", input.absolutePath)
		println(result)
	}

	fun ffmpegPackVideo(fps: Int, inputImages: File, inputAudio: File, output: File) {
		passthru(
			ffmpeg,
			"-y",
			"-framerate", "$fps",
			"-i", "${inputImages.absolutePath}/%06d.png",
			"-i", inputAudio.absolutePath,

			"-c:v", "libx264",
			//"-c:a", "aac",
			//"-b:a", "192k",

			"-r", "$fps",
			"-vf", "fps=$fps",

			//"-strict", "experimental",
			"-pix_fmt", "yuv420p",
			"-shortest",
			output.absolutePath
		)
	}

	fun convertVideo(fps: Int, input: File, output: File) {
		val wav = File("${input.absolutePath}.wav")
		val images1x = File("${input.absolutePath}.images1x")
		val images2x = File("${input.absolutePath}.images2x")
		ffmpegExtractAudio(input, wav)
		ffmpegExtractImages(input, images1x)

		waifu2x(images1x, images2x)
		/*
		for (file in images.listFiles()) {
			println(file)
			waifu2x(file, file)
		}
		*/

		ffmpegPackVideo(30, images2x, wav, output)
	}

	fun convertVideoLastStep(fps: Int, input: File, output: File) {
		val wav = File("${input.absolutePath}.wav")
		val images2x = File("${input.absolutePath}.images2x")
		ffmpegPackVideo(fps, images2x, wav, output)
	}

	fun extractDl1(dl1: File, out: File) {
		out.mkdirs()
		val files = DL1.read(dl1.open2("r"))
		for ((name, data) in files) {
			val compressed = data.readAll()
			val uncompressed = if (LZ.isCompressed(compressed)) LZ.uncompress(compressed) else compressed
			println(name)
			out[name] = uncompressed
		}
	}

	@JvmStatic fun main(args: Array<String>) {
		val base = File("D:/juegos/dividead")
		if (!base["CS_ROGO.AVI.2x.mp4"].exists()) convertVideo(30, base["CS_ROGO.AVI"], base["CS_ROGO.AVI.2x.mp4"])
		if (!base["OPEN.AVI.2x.mp4"].exists()) convertVideo(15, base["OPEN.AVI"], base["OPEN.AVI.2x.mp4"])
		if (!base["SG.DL1.d"].exists()) extractDl1(base["SG.DL1"], base["SG.DL1.d"])
		if (!base["SG.DL1.2x.d"].exists()) waifu2x(base["SG.DL1.d"], base["SG.DL1.2x.d"])
	}
}
