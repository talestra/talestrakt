package com.talestra.tod

/*
class Translation {
	string[][uint] texts;

	void load(Stream data) {
		texts = null;
		while (!data.eof) {
			ushort room_id, text_count, text_id, text_len;
			data.read(room_id);
			data.read(text_count);
			for (int n = 0; n < text_count; n++) {
				data.read(text_id);
				data.read(text_len);

				auto text = data.readString(text_len);

				if ((room_id in texts) is null) texts[room_id] = [];
				if (texts[room_id].length <= text_id) texts[room_id].length = text_id + 1;
				texts[room_id][text_id] = cast(string)text;
			}
		}
	}
}
*/
