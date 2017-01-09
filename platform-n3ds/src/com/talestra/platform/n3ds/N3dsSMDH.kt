package com.talestra.platform.n3ds

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.color.BGR_565
import com.soywiz.korio.stream.*
import java.util.*

// https://www.3dbrew.org/wiki/SMDH
// Icon
object N3dsSMDH {
	data class ApplicationTitle(
		val short: String,
		val long: String,
		val publisher: String
	)

	fun readApplicationTitle(s: SyncStream): ApplicationTitle {
		val short = s.readString(0x80, Charsets.UTF_16LE).trimEnd(0.toChar())
		val long = s.readString(0x100, Charsets.UTF_16LE).trimEnd(0.toChar())
		val publisher = s.readString(0x80, Charsets.UTF_16LE).trimEnd(0.toChar())
		return ApplicationTitle(short, long, publisher)
	}

	fun readApplicationTitles(s: SyncStream) = (0 until 12).map { N3dsLocales[it] to readApplicationTitle(s) }.toMap()

	class ApplicationSettings(
	)

	fun readApplicationSettings(s: SyncStream): ApplicationSettings {
		val gameRatings = s.readBytes(0x10)
		val regionLockout = s.readS32_le()
		val matchMakerId = s.readBytes(0x0C)
		val flags = s.readS32_le()
		val eulaVersion = s.readS16_le()
		val reserved = s.readS16_le()
		val optimalAnimationDefaultFrameForBNR = s.readS32_le()
		val cecStreetPassId = s.readS32_le()
		return ApplicationSettings()
	}

	class Icons(val small: Bitmap32, val large: Bitmap32)

	fun readIcon(s: SyncStream): Icons {
		val small = s.readBytes(0x480)
		val large = s.readBytes(0x1200)
		val smallImage = Bitmap32(24, 24).writeDecoded(BGR_565, small).deswizzle(2)
		val largeImage = Bitmap32(48, 48).writeDecoded(BGR_565, large).deswizzle(2)
		return Icons(smallImage, largeImage)
	}

	class SMDH(
		val titles: Map<Locale, ApplicationTitle>,
		val settings: ApplicationSettings,
		val icons: Icons
	)

	fun read(s: SyncStream): SMDH {
		if (s.readStringz(4) != "SMDH") throw IllegalArgumentException("Not a SMDH section")
		val version = s.readU16_le()
		val reserved = s.readU16_le()
		val titles = readApplicationTitles(s.readSlice(0x2000))
		val settings = readApplicationSettings(s.readSlice(0x30))
		s.readS64_le()
		val icons = readIcon(s.readSlice(0x1680))
		return SMDH(
			titles,
			settings,
			icons
		)
	}
}
