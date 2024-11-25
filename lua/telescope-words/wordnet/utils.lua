local fzy = require("fzy")

local M = {}

---Get the root directory
---@return string
function M.get_root_dir()
	local info = debug.getinfo(1, "S")
	local script_path = info.source:sub(2)
	return vim.fn.fnamemodify(script_path, ":p:h:h:h:h")
end

---@param t1 any[]
---@param t2 any[]
---@return any[]
function M.join_arrays(t1, t2)
	local result = {}
	for i = 1, #t1 do
		result[#result + 1] = t1[i]
	end
	for i = 1, #t2 do
		result[#result + 1] = t2[i]
	end
	return result
end

---Take a lemma (index representation of a word) and format it for display
---@param word_raw string
---@return string
function M.format_word_for_display(word_raw)
	return word_raw:gsub("%b()", ""):gsub("_", " ")
end

---Check if a given value is in a table (which is an array)
---@param array any[]
---@param value any
---@return boolean
function M.array_contains(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

---@param array any[]
---@return any[]
function M.remove_duplicates(array)
	local unique = {}
	for _, item in ipairs(array) do
		if not M.array_contains(unique, item) then
			table.insert(unique, item)
		end
	end
	return unique
end

---Search for a word in an array. If present move to the start.
---@param array string[]
---@param word string
---@return any[]
function M.move_word_to_start_of_array(array, word)
	-- Find the index of the value in the array
	local index = nil
	local match = nil
	for i, v in ipairs(array) do
		if v:lower() == word:lower() then
			index = i
			match = v
			break
		end
	end
	if index then
		table.remove(array, index)
		table.insert(array, 1, match)
	end

	return array
end

---Sort sense index entries by sense integer (increasing), and tag count (decreasing). Sense number has priority.
---@param entries SenseIndexEntry
function M.sort_index_entries_by_sense_number_and_tag_count(entries)
	table.sort(entries, function(entry1, entry2)
		if entry1.sense_number == entry2.sense_number then
			return entry1.tag_count > entry2.tag_count -- Descending tag_count if sense_numbers are the same
		else
			return entry1.sense_number < entry2.sense_number -- Ascending sense_number if sense_numbers are different
		end
	end)
end

---@param matches string[]
---@param search_term string
function M.sort_word_matches_by_fzy_score(matches, search_term)
	table.sort(matches, function(entry1, entry2)
		local entry1_score = fzy.score(search_term, entry1)
		local entry2_score = fzy.score(search_term, entry2)
		if entry1_score == entry2_score then
			return entry1 > entry2
		else
			return entry1_score >= entry2_score
		end
	end)
end

return M
