package com.talestra.platform.n3ds

enum class N3dsRegions(val bit: Int) {
	JAPAN(0x01),
	NORTH_AMERICA(0x02),
	EUROPE(0x04),
	AUSTRALIA(0x08),
	CHINA(0x10),
	KOREA(0x20),
	TAIWAN(0x40);
}