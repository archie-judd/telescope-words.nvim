local M = {}

---Get the root directory
---@return string
function M.get_root_dir()
	local info = debug.getinfo(1, "S")
	local script_path = info.source:sub(2)
	return vim.fn.fnamemodify(script_path, ":p:h:h:h")
end

---@generic T : any
---@param t1 T[]
---@param t2 T[]
---@return T[]
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

---Take a lemma (index representation of a word)
---@param word_raw string
---@return string
function M.prettify_word(word_raw)
	return word_raw:gsub("%(.%)", ""):gsub("_", " ")
end

---Check if a given value is in a table (which is an array)
---@generic T : any
---@param array T[]
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

---@generic T : any
---@param array T[]
---@return T[]
function M.remove_duplicates(array)
	local unique = {}
	for _, item in ipairs(array) do
		if not M.array_contains(unique, item) then
			table.insert(unique, item)
		end
	end
	return unique
end

---Sort sense index entries by sense integer (increasing), and tag count (decreasing). Sense number has priority.
---@param entries SenseIndexEntry
---@return SenseIndexEntry
function M.sort_sense_index_entries(entries)
	table.sort(entries, function(entry1, entry2)
		if entry1.sense_number == entry2.sense_number then
			return entry1.tag_count > entry2.tag_count -- Descending tag_count if sense_numbers are the same
		else
			return entry1.sense_number < entry2.sense_number -- Ascending sense_number if ages are different
		end
	end)
end

return M
