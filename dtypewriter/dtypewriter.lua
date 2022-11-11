----------------------------------------------------------------------
-- LICENSE
----------------------------------------------------------------------

-- MIT License

-- Copyright (c) 2022 Klayton Kowalski

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- https://github.com/klaytonkowalski/library-defold-typewriter

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

local dtypewriter = {}

local _container_node

local _font_id
local _font

local _text_area_x
local _text_area_y
local _text_area_width

local _line_count_max
local _line_offset

local _chunks = {}

local _characters = {}
local _character_index
local _paragraph_index

local _waiting = false

local _colors = {}
local _default_color = vmath.vector4()

local _speed_max = 120
local _speed = 30

local _messages_url

----------------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------------

dtypewriter.messages =
{
	start = hash("start"),
	type = hash("type"),
	wait = hash("wait"),
	continue = hash("continue"),
	complete = hash("complete")
}

----------------------------------------------------------------------
-- LOCAL FUNCTIONS
----------------------------------------------------------------------

local function strip_spaces(text)
	local remove_consecutive_spaces = string.gsub(text, "%s+", " ")
	local remove_front_spaces = string.gsub(remove_consecutive_spaces, "^%s+", "")
	local remove_back_spaces = string.gsub(remove_front_spaces, "%s+$", "")
	local remove_line_spaces = string.gsub(remove_back_spaces, "%s*<line>%s*", "<line>")
	return remove_line_spaces
end

local function add_chunk(type, text)
	local chunk = { type = type, text = text }
	_chunks[#_chunks + 1] = chunk
end

local function add_character(chunk_index, text, color, speed)
	local character_data = { chunk_index = chunk_index, text = text, color = color, speed = speed }
	_characters[#_characters + 1] = character_data
end

local function set_transparent(color)
	return vmath.vector4(color.x, color.y, color.z, 0)
end

local function type_callback()
	msg.post(_messages_url, dtypewriter.messages.type)
	local character_data = _characters[_character_index]
	gui.set_color(character_data.node, character_data.color)
	_character_index = _character_index + 1
	local next_character_data = _characters[_character_index]
	if next_character_data then
		if character_data.paragraph < next_character_data.paragraph then
			msg.post(_messages_url, dtypewriter.messages.wait)
			_waiting = true
		else
			timer.delay(1 / next_character_data.speed, false, type_callback)
		end
	else
		msg.post(_messages_url, dtypewriter.messages.complete)
	end
end

----------------------------------------------------------------------
-- MODULE FUNCTIONS
----------------------------------------------------------------------

function dtypewriter.init(container_node_id, font_id, text_area_x, text_area_y, text_area_width, line_count_max, line_offset, messages_url)
	dtypewriter.clear()
	_container_node = gui.get_node(container_node_id)
	_font_id = font_id
	_font = gui.get_font_resource(font_id)
	_text_area_x = text_area_x
	_text_area_y = text_area_y
	_text_area_width = text_area_width
	_line_count_max = line_count_max
	_line_offset = line_offset
	_messages_url = messages_url
end

function dtypewriter.clear()
	_text_raw = nil
	_chunks = {}
	for _, character_data in ipairs(_characters) do
		gui.delete_node(character_data.node)
	end
	_characters = {}
	_character_index = nil
	_paragraph_index = nil
	_waiting = false
end

function dtypewriter.load(text)
	dtypewriter.clear()
	text = strip_spaces(text)
	local chunk_start_index = 1
	local character_index = 1
	local character_color = _default_color
	local character_speed = _speed
	while character_index <= #text do
		local character = string.sub(text, character_index, character_index)
		if character == " " then
			local chunk_type = "content"
			local chunk_text = string.sub(text, chunk_start_index, character_index - 1)
			add_chunk(chunk_type, chunk_text)
			chunk_text = " "
			chunk_type = "space"
			add_chunk(chunk_type, chunk_text)
			add_character(#_chunks, " ", character_color, character_speed)
			chunk_start_index = character_index + 1
			character_index = character_index + 1
		elseif character == "<" then
			if string.sub(text, character_index, character_index + 6) == "<color=" then
				local color_start_index, color_end_index = string.find(text, "%l+", character_index + 7)
				local color_name = string.sub(text, color_start_index, color_end_index)
				character_color = (color_name == "default" or not _colors[color_name]) and _default_color or _colors[color_name]
				text = string.sub(text, 1, character_index - 1) .. string.sub(text, color_end_index + 2)
			elseif string.sub(text, character_index, character_index + 6) == "<speed=" then
				local speed_start_index, speed_end_index = string.find(text, "%d*%l*", character_index + 7)
				local speed_text = string.sub(text, speed_start_index, speed_end_index)
				character_speed = speed_text == "default" and _speed or math.min(_speed_max, math.max(0, speed_text))
				text = string.sub(text, 1, character_index - 1) .. string.sub(text, speed_end_index + 2)
			elseif string.sub(text, character_index, character_index + 5) == "<line>" then
				local chunk_type = "content"
				local chunk_text = string.sub(text, chunk_start_index, character_index - 1)
				add_chunk(chunk_type, chunk_text)
				chunk_type = "line"
				add_chunk(chunk_type)
				chunk_start_index = character_index + 6
				character_index = character_index + 6
			elseif string.sub(text, character_index, character_index + 10) == "<paragraph>" then
				local chunk_type = "content"
				local chunk_text = string.sub(text, chunk_start_index, character_index - 1)
				add_chunk(chunk_type, chunk_text)
				chunk_type = "paragraph"
				add_chunk(chunk_type)
				chunk_start_index = character_index + 11
				character_index = character_index + 11
			end
		else
			add_character(#_chunks + 1, character, character_color, character_speed)
			if character_index == #text then
				local chunk_type = "content"
				local chunk_text = string.sub(text, chunk_start_index, character_index)
				add_chunk(chunk_type, chunk_text)
			end
			character_index = character_index + 1
		end
	end
	local text_metrics = resource.get_text_metrics(_font, text)
	local paragraph = 1
	local line = 1
	local line_width_remaining = _text_area_width
	local character_x = _text_area_x
	for chunk_index, chunk in ipairs(_chunks) do
		local chunk_metrics = resource.get_text_metrics(_font, chunk.text or "")
		if line_width_remaining - chunk_metrics.width < 0 or chunk.type == "line" then
			line = line + 1
			line_width_remaining = _text_area_width
			if line > _line_count_max then
				line = 1
				paragraph = paragraph + 1
			end
			character_x = _text_area_x
			if chunk.type == "space" then
				goto continue
			end
		elseif chunk.type == "paragraph" then
			line = 1
			line_width_remaining = _text_area_width
			paragraph = paragraph + 1
			character_x = _text_area_x
		end
		if chunk.text then
			for _, character_data in ipairs(_characters) do
				if character_data.chunk_index == chunk_index then
					local character_metrics = resource.get_text_metrics(_font, character_data.text)
					local character_position = vmath.vector3(character_x, -_text_area_y - (line - 1) * text_metrics.height + (line - 1) * _line_offset, 0)
					character_x = character_x + character_metrics.width + 1
					line_width_remaining = line_width_remaining - character_metrics.width - 1
					local character_node = gui.new_text_node(character_position, character_data.text)
					gui.set_parent(character_node, _container_node)
					gui.set_font(character_node, _font_id)
					gui.set_color(character_node, set_transparent(character_data.color))
					gui.set_adjust_mode(character_node, gui.ADJUST_FIT)
					gui.set_pivot(character_node, gui.PIVOT_NW)
					character_data.node = character_node
					character_data.paragraph = paragraph
				end
			end
		end
		::continue::
	end
end

function dtypewriter.start()
	if #_characters > 0 and not _character_index then
		msg.post(_messages_url, dtypewriter.messages.start)
		_character_index = 1
		_paragraph_index = 1
		if _speed == 0 then
			
		else
			timer.delay(1 / _speed, false, type_callback)
		end
	end
end

function dtypewriter.continue()
	if _waiting then
		msg.post(_messages_url, dtypewriter.messages.continue)
		_waiting = false
		_paragraph_index = _paragraph_index + 1
		character_index = 1
		while character_index < _character_index do
			local character_data = _characters[character_index]
			gui.set_color(character_data.node, set_transparent(character_data.color))
			character_index = character_index + 1
		end
		timer.delay(1 / _speed, false, type_callback)
	end
end

function dtypewriter.set_color(name, color)
	_colors[name] = color
end

function dtypewriter.set_default_color(color)
	_default_color = color
end

function dtypewriter.clear_colors()
	_colors = {}
end

function dtypewriter.set_speed(speed)
	_speed = math.min(_speed_max, math.max(0, speed))
end

function dtypewriter.is_clear()
	return not _character_index and #_characters == 0
end

function dtypewriter.is_loaded()
	return not _character_index and #_characters > 0
end

function dtypewriter.is_typing()
	return _character_index < #_characters
end

function dtypewriter.is_waiting()
	return _waiting
end

function dtypewriter.is_complete()
	return _character_index == #_characters + 1
end

return dtypewriter