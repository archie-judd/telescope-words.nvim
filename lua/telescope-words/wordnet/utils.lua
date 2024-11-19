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

---Take a lemma (index representation of a word)
---@param word_raw string
---@return string
function M.prettify_word(word_raw)
	return word_raw:gsub("%(.%)", ""):gsub("_", " ")
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

---Search for a value in an array. If present move to the start.
---@param array any[]
---@param value any
---@return any[]
function M.move_to_start_of_array(array, value)
	-- Find the index of the value in the array
	local index = nil
	for i, v in ipairs(array) do
		if v == value then
			index = i
			break
		end
	end
	if index then
		table.remove(array, index)
		table.insert(array, 1, value)
	end

	return array
end

---Sort sense index entries by sense integer (increasing), and tag count (decreasing). Sense number has priority.
---@param entries SenseIndexEntry
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
