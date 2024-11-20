local config = require("telescope-words.wordnet.config")
local parse = require("telescope-words.wordnet.parse")
local utils = require("telescope-words.wordnet.utils")

local M = {}

---Get the index entries for a given search term, returning the lines where `match_function(line, search_term)` is true.
---Uses binary search to minimise the integer of lines read.
---@param match_function MatchFunction
---@param search_term string
---@return string[]
local function get_index_entries_by_match_function(match_function, search_term)
	local file = io.open(config.INDEX_FILEPATH, "r")
	if not file then
		error("Cannot open file: " .. config.INDEX_FILEPATH)
	end

	-- Find the file size and go back to the beginning
	file:seek("end")
	local file_size = file:seek("cur")
	file:seek("set")

	local low, high = 0, file_size
	local first_match

	-- Binary search for the start of the chunk
	while low < high do
		local mid = math.floor((low + high) / 2)
		file:seek("set", mid)
		local _ = file:read("*l") -- Skip partial line
		local entry = file:read("*l") -- Read the actual line
		if entry and entry >= search_term then
			high = mid
		else
			low = mid + 1
		end
	end

	-- At this point, `low` points to the first line >= prefix
	file:seek("set", low)
	_ = file:read("*l") -- Skip partial line
	local start_pos = file:seek("cur")

	-- Backward scan to find the first match
	local pos = start_pos
	while pos > 0 do
		pos = pos - 1
		file:seek("set", pos)
		if file:read(1) == "\n" or pos == 0 then
			-- If we've reached a newline or the beginning of the file
			-- This means we've reached the start of a new line
			file:seek("set", pos == 0 and 0 or pos + 1) -- Adjust the pointer to the start of the line
			local entry = file:read("*l") -- Read the full line starting from this position
			if entry and match_function(entry, search_term) then
				-- Check if the line matches the prefix
				first_match = file:seek("cur") - #entry - 1 -- Mark the position of the first match
			else
				-- Stop scanning if we find a non-matching line
				break
			end
		end
	end

	-- Forward scan to find all matching lines
	first_match = first_match or start_pos
	local matched = {}
	file:seek("set", first_match)

	repeat
		local entry = file:read("*l")
		if entry and match_function(entry, search_term) then
			table.insert(matched, entry)
		else
			break
		end

	until not entry

	file:close()
	return matched
end

---Return true if the word in the entry matches the search term exactly
---@param entry_raw string
---@param search_term string
---@return boolean
local function word_matches_exactly(entry_raw, search_term)
	return entry_raw:match("^(.-)%%") == search_term
end

---Returns a match function that checks if the first n letters of the line match the search term
---@param n integer
---@return MatchFunction
local function get_first_n_letters_match(n)
	return function(entry_raw, search_term)
		return string.sub(entry_raw, 1, n) == string.sub(search_term, 1, n)
	end
end

----Get the data file path for a given word syntactic category (pos)
---@param ss_type_num SynsetTypeNumber
---@return DataFilePath
function M.get_data_filepath_for_synset_type(ss_type_num)
	local path = nil
	if ss_type_num == 1 then
		path = config.DATA_NOUN_FILEPATH
	elseif ss_type_num == 2 then
		path = config.DATA_VERB_FILEPATH
	elseif ss_type_num == 3 then
		path = config.DATA_ADJ_FILEPATH
	elseif ss_type_num == 4 then
		path = config.DATA_ADV_FILEPATH
	elseif ss_type_num == 5 then
		path = config.DATA_ADJ_FILEPATH
	else
		error("Invalid ss type: " .. ss_type_num)
	end
	return path
end

----Get the data file path for a given word syntactic category (pos)
---@param pos PartOfSpeech
---@return DataFilePath
function M.get_data_filepath_for_pos(pos)
	local path = nil
	if pos == "n" then
		path = config.DATA_NOUN_FILEPATH
	elseif pos == "v" then
		path = config.DATA_VERB_FILEPATH
	elseif pos == "a" then
		path = config.DATA_ADJ_FILEPATH
	elseif pos == "r" then
		path = config.DATA_ADV_FILEPATH
	else
		error("Invalid word type: " .. pos)
	end
	return path
end

---Get the data entry for a given byte offset
---@param data_filepath DataFilePath
---@param byte_offset integer
---@return Synset
function M.get_synset_entry_for_byte_offset(data_filepath, byte_offset)
	local file = io.open(data_filepath, "r")
	if not file then
		error("Unable to open file: " .. data_filepath)
	end
	file:seek("set", byte_offset)
	local synset = file:read("*l")
	file:close()
	synset = parse.parse_synset_entry(synset)
	return synset
end

---For a given word, read all index entries from all index files
---@param search_term string
---@return SenseIndexEntry[]
function M.get_exact_index_matches_for_word(search_term)
	local entries = {}
	local raw_entries = get_index_entries_by_match_function(word_matches_exactly, search_term)
	for _, raw_entry in ipairs(raw_entries) do
		local index_entry = parse.parse_sense_index_entry(raw_entry)
		if index_entry then
			table.insert(entries, index_entry)
		end
	end
	return entries
end

---Return the index entries for a given search term, where the search term is a substring of the word in the entry
---@param search_term string
---@return string[]
function M.get_fuzzy_index_matches_for_word_raw(search_term, char_search_threshold)
	if #search_term < char_search_threshold then
		return {}
	end
	local first_n_letters_match = get_first_n_letters_match(char_search_threshold)
	local raw_entries = get_index_entries_by_match_function(first_n_letters_match, search_term)
	return raw_entries
end

return M
