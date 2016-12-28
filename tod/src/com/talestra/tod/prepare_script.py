#!/usr/bin/python
# -*- coding: iso-8859-15 -*-

import zipfile
import re
import struct

# print struct.pack('<3bh', 60, 65, 70, 32400)

class Acme:
	def __init__(self, file_name, fix_characters):
		self.zip = zipfile.ZipFile(file_name)
		self.chrtbl = dict()
		for n in xrange(0, 256):
			self.chrtbl[chr(n)] = chr(n)

		#if fix_characters:
		#	self.chrtbl["á"] = "áá"
		#	self.chrtbl["é"] = "áé"
		#	self.chrtbl["í"] = "áí"
		#	self.chrtbl["ó"] = "áó"
		#	self.chrtbl["ú"] = "áú"
		#	self.chrtbl["Á"] = "áÁ"
		#	self.chrtbl["É"] = "áÉ"
		#	self.chrtbl["Í"] = "áÍ"
		#	self.chrtbl["Ó"] = "áÓ"
		#	self.chrtbl["Ú"] = "áÚ"
		#	self.chrtbl["ñ"] = "áñ"
		#	self.chrtbl["Ñ"] = "áÑ"
		#	self.chrtbl["ü"] = "áü"

		self.chara_map = dict()
		for i, name in enumerate(["STAHN", "RUTEE", "LEON", "GARR", "PHILIA", "MARY", "KARYL", "CHELSEA", "BRUIRSER", "LILIS"]):
			self.chara_map[name] = i + 1

		self.color_map = dict()
		for i, name in enumerate(["TRANS", "BLUE", "RED", "PINK", "GREEN", "CYAN", "YELLOW", "GREY", "BLACK", "LIGHTBLUE", "LIGHTRED", "LIGHTPINK", "LIGHTGREEN", "LIGHTCYAN", "LIGHTYELLOW", "WHITE"]):
			self.color_map[name] = i

		self.style_map = dict()
		for i, name in enumerate(["BI", "-", "B", "I"]):
			self.style_map[name] = i

	def hexdigits_as_array(self, digits, expected_len):
		a = ''
		for n in xrange(0, len(digits), 2):
			a += chr(int(digits[n:n + 2], 16))
		assert(len(a) == expected_len);
		return a
	
	def process_string(self, text):
		r = ''
		n = 0
		skip_next_linefeed = False
		text = text.replace("\r\n", "\n")
		while n < len(text):
			c = text[n]
			if c == '<':
				m = n
				while n < len(text) and text[n] != '>': n += 1
				special = text[m:n + 1]
				matches = re.search(r'<(\w+)(:(.+))?>', special)
				if not matches is None:
					type  = matches.group(1)
					value = matches.group(3)
					if   type == '00'    : r += struct.pack('<B' , 0x00)
					elif type == '60'    : r += struct.pack('<B' , 0x60)
					elif type == 'CHARA' : r += struct.pack('<BB', 0x01, self.chara_map[value])
					elif type == 'DELAY' : r += struct.pack('<BB', 0x03, int(value, 16))
					elif type == 'COLOR' : r += struct.pack('<BB', 0x04, self.color_map[value])
					elif type == 'UNK'   : r += struct.pack('<B' , 0x05)
					elif type == 'STYLE' : r += struct.pack('<BB', 0x09, self.style_map[value])
					elif type == 'PAGE'  :
						if len(r) and r[-1] == '\n':
							r = r[0:-1]; # Remove previous linefeed

						r += struct.pack('<B' , 0x0C)
						skip_next_linefeed = True
					elif type == 'SVAR'  :
						r += struct.pack('<BI', 0x02, int(value, 16))
						#r += self.hexdigits_as_array(value, 4)
						#print('SVAR: "' + r + '"')
					elif type == 'IVAROP':
						r += struct.pack('<BH', 0x06, int(value, 16))
						#r += self.hexdigits_as_array(value, 2)
					elif type == 'COUNT' :
						r += struct.pack('<BH', 0x07, int(value, 16))
						#r += self.hexdigits_as_array(value, 2)
					elif type == 'IVAR'  :
						r += struct.pack('<BH', 0x08, int(value, 16))
						#r += self.hexdigits_as_array(value, 2)
					else:
						#print text
						print 'Invalid type "%s"' % (matches.group(0))
						#raise Exception('Invalid type "%s"' % (matches.group(0)))
						cstr = ''.join([self.chrtbl[c] for c in str(matches.group(0))])
						#print cstr
						r += cstr
			elif c == '\n':
				if skip_next_linefeed:
					skip_next_linefeed = False
				else:
					r += '\n'
			else:
				r += self.chrtbl[c]
			n += 1
		return r

	def process_entry(self, info, data):
		matches = re.split(r'(## POINTER (\d+).*)', data)
		self.f.write(struct.pack('<H', len(matches) / 3))
		for n in xrange(1, len(matches), 3):
			id   = int(matches[n + 1])
			text = self.process_string(matches[n + 2][1:].rstrip(" \r\n\t"))
			#print text
			self.f.write(struct.pack('<HH', id, len(text)) + text)

	def process(self, outputFile):
		self.f = file(outputFile, 'wb')
		try:
			for info in self.zip.infolist():
				matches = re.search(r'^SRC/(\d+)\.txt$', info.filename)
				if not matches is None:
					room_id = int(matches.group(1), 10)

					print(room_id)
					self.f.write(struct.pack('<H', room_id))

					data = self.zip.read(info.filename)
					self.process_entry(info, data);
					#print info.filename
					#self.f.close()
					#return
		finally:
			self.f.close()

acme = Acme('tod.zip', True)
acme.process('res/script.bin')

#acme = Acme('tod_items.zip', False)
#acme.process('res/items.bin')

#acme = Acme('tod_skills.zip', False)
#acme.process('res/skills.bin')

#acme = Acme('tod_items_original.zip', False)
#acme.process('res/items_original.bin')

#acme = Acme('tod_skills_original.zip', False)
#acme.process('res/skills_original.bin')
