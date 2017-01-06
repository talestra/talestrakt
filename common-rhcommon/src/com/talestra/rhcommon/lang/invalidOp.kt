package com.talestra.rhcommon.lang

fun invalidOp(msg: String = "Invalid Operation"): Nothing = throw IllegalArgumentException(msg)