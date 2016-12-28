package com.talestra.yume.util

import org.jcodec.containers.mps.MPSDemuxer

fun main(args: Array<String>) {
	EventLoop.mainAsync {
		MPSDemuxer()
	}
}