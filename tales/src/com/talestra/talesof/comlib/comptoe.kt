package com.talestra.talesof.comlib

import java.io.ByteArrayOutputStream
import java.io.PrintStream

private const val VERSION = "1.31b"

fun main(argv: Array<String>) {
	// Modificadores
	var modifier = 0
	var raw = 0
	var silent = false
	var once = false

	fun show_header_once() {
		if (once || silent) return
		println("Compressor/Decompressor utility for 'Tales of...' Games - version $VERSION")
		println("Copyright (C) 2006-2007 soywiz - http://www.tales-tra.com/")
		once = true
	}

	val argc = argv.size
	var retval = 0
	val dparams = arrayListOf("", "")
	var paramc = 0
	var params = -1

	val temp = ByteArray(0x1000)
	var done = 0
	var source = ""

	var action = ACTION.NONE

	fun setparams(p: Int) {
		params = p
		paramc = 0
	}

	if (argc <= 1) {
		action = ACTION.HELP
		setparams(0)
	}

	for (n in 1..argc) {
		val arg = if (n < argc) argv[n] else ""


		if (arg == "-?" || arg == "-h" || arg == "--help") {
			//show_help()
			action = ACTION.HELP
			setparams(0)
		}

		if (arg == "-r" || arg == "-raw") {
			raw = 1
			continue
		}
		if (arg == "-s") {
			silent = true
			System.setOut(PrintStream(ByteArrayOutputStream()))
			continue
		}


		if (arg[0] == '-') {
			var cnt = 1

			when (arg[1]) {
				'c' -> {
					action = ACTION.ENCODE; setparams(2); } // // Codificad
				'd' -> {
					action = ACTION.DECODE; setparams(2); } // Decodificia
				't' -> {
					action = ACTION.TEST; setparams(1); } // Comprueba
				'p' -> {
					action = ACTION.PROFILE; setparams(1); } // Crea un perfil de compresión
				'b' -> {
					action = ACTION.BDUMP; setparams(1); } // Dumpea el text_buffer inicial
				else -> {
					cnt = 0; }
			}

			if (cnt != 0) {
				done = 0
				modifier = if ((arg.length) >= 3) arg.substring(2).toInt() else 3
				continue
			}
		}


		if ((n < argc) && (paramc < params)) {
			dparams[paramc++] = arg
		}

		if (paramc >= params) {
			show_header_once()

			done = 1
			when (action) {
				ACTION.ENCODE -> {
					if (dparams[0] != dparams[1]) {
						EncodeFile(dparams[0], dparams[1], raw, modifier)
					} else {
						System.err.println("Can't use same file for input and output")
						retval = retval or -1
					}
				}
				ACTION.DECODE -> {
					if (dparams[0] != dparams[1]) {
						DecodeFile(dparams[0], dparams[1], raw, modifier)
					} else {
						System.err.println("Can't use same file for input and output")
						retval = retval or -1
					}
				}
				ACTION.PROFILE -> {
					if (arg.length < 0x900) {
						ProfileStart("$arg.profile")
						DecodeFile(dparams[0], null, raw, modifier)
						ProfileEnd()
					}
				}
				ACTION.BDUMP -> {
					DumpTextBuffer(dparams[0])
				}
				ACTION.TEST -> {
					CheckCompression(dparams[0], modifier)
				}
				ACTION.HELP -> {
					show_help()
				}
				else -> {
					if (n == argc) {
						if (paramc == params || params == 0) System.exit(retval)
						if (params == -1) show_help()
						System.err.println("Expected $params params, but $paramc given")
						System.exit(-1)
					}
					System.err.println("Unknown parameter '$arg'")
					System.exit(-1)
				}
			}

			paramc = 0
			params = 0
			action = ACTION.NONE
		}
	}

	show_header_once()

	System.err.println("Expected $params params, but $paramc given\n")
	System.exit(-1)
}

fun show_help() {
	println("<Modifiers>")
	println("  -s silent mode")
	println("  -r use raw files")
	println("")
	println("<Commands>")
	println("  -b <file.out> buffer dump")
	println("  -c[<V>] compress <file.in> <file.out>")
	println("  -d[<V>] uncompress <file.in> <file.out>")
	println("  -t[<V>] tests uncompress/compress/uncompress <file.in>")
	println("  -p[<V>] make profile of compression <file.in>")
	println("  \t<V> -> (1 - LZSS | 3 - LZSS+RLE)")
	System.exit(-1)
}

private enum class ACTION { NONE, ENCODE, DECODE, TEST, PROFILE, BDUMP, HELP }
