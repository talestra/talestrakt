package com.talestra.platform.psp

import com.soywiz.korio.stream.AsyncStream

suspend fun AsyncStream.cso() = CSO.read(this)
