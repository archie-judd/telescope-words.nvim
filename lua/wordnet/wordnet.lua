local format = require("wordnet.format")
local read = require("wordnet.read")
local types = require("wordnet.types")
local utils = require("wordnet.utils")

local M = {}

---Parse a synset entry and include synset information with each pointer
---@param synset Synset
---@return FullSynset
local function get_full_synset_for_synset(synset)
	local full_pts = {}
	for _, ptr in ipairs(synset.pts) do
		local data_filepath = read.get_data_filepath_for_pos(ptr.pos)
		local ptr_synset = read.get_synset_entry_for_byte_offset(data_filepath, ptr.synset_offset)
		local ptr_full = {
			pointer_symbol = ptr.pointer_symbol,
			synset_offset = ptr.synset_offset,
			pos = ptr.pos,
			source_target = ptr.source_target,
			synset = ptr_synset,
		}
		table.insert(full_pts, ptr_full)
	end

	local full_synset = types.FullSynset.new(
		synset.synset_offset,
		synset.lex_filenum,
		synset.ss_type,
		synset.w_cnt,
		synset.words,
		synset.p_cnt,
		full_pts,
		synset.gloss
	)
	return full_synset
end

---Get all full synsets for a given word
---@param word string
---@return FullSynset[]
local function get_full_synsets_for_word(word)
	local entries = read.get_sense_index_entries_for_word(word)
	local full_synsets = {}
	for _, entry in ipairs(entries) do
		local data_filepath = read.get_data_filepath_for_synset_type(entry.ss_type)
		local synset = read.get_synset_entry_for_byte_offset(data_filepath, entry.synset_offset)
		local synset_full = get_full_synset_for_synset(synset)
		table.insert(full_synsets, synset_full)
	end
	return full_synsets
end

---Find all words in a synset that are similar to the search word. Returns exact synonyms, all "similar to" words, all
---of their exact synonyms, and all of their "similar to" words too. This could be recursive with a user-defined depth.
---@param full_synset FullSynset
---@param search_word string
---@return string[]
local function get_similar_words_for_synset(full_synset, search_word)
	local similar_words = {}
	for _, word in ipairs(full_synset.words) do
		if word.word ~= search_word then
			table.insert(similar_words, word.word)
		end
	end
	for _, full_ptr in ipairs(full_synset.full_pts) do
		if full_ptr.pointer_symbol == "&" or full_ptr.pointer_symbol == "^" then
			for _, word in ipairs(full_ptr.synset.words) do
				if word.word ~= search_word then
					table.insert(similar_words, word.word)
				end
			end
			if full_ptr.pointer_symbol == "&" then
				local full_ptr_synset = get_full_synset_for_synset(full_ptr.synset)
				for _, ptr_ptr in ipairs(full_ptr_synset.full_pts) do
					if ptr_ptr.pointer_symbol == "&" then
						for _, word in ipairs(ptr_ptr.synset.words) do
							if word.word ~= search_word then
								table.insert(similar_words, word.word)
							end
						end
					end
				end
			end
		end
	end
	return similar_words
end

---Return all the words in the index that starat with the search term
---@param search_term string
---@param char_threshold integer
---@return string[]
function M.get_index_word_matches(search_term, char_threshold)
	local matches = {}
	search_term = search_term:lower():gsub(" ", "_")
	-- do not search for strings with fewer chars than char_threshold
	if #search_term < math.max(char_threshold, 2) then
		return {}
	end
	local matches_raw = read.get_words_beginning_with_string_in_index(search_term)
	matches_raw = utils.remove_duplicates(matches_raw)
	for i, match_raw in ipairs(matches_raw) do
		matches[i] = utils.prettify_word(match_raw)
	end
	return matches
end

---Find the exact word in the index, get the synset, and then find and return all similar words
---@param search_word any
---@return string[]
function M.get_similar_words_for_word(search_word)
	local similar_words = {}
	search_word = search_word:lower():gsub(" ", "_")
	local full_synsets = get_full_synsets_for_word(search_word)
	local similar_words_raw = {}
	for _, full_synset in ipairs(full_synsets) do
		local _similar_words_raw = get_similar_words_for_synset(full_synset, search_word)
		similar_words_raw = utils.join_arrays(similar_words_raw, _similar_words_raw)
	end
	similar_words_raw = utils.remove_duplicates(similar_words_raw)
	for i, similar_word_raw in ipairs(similar_words_raw) do
		similar_words[i] = utils.prettify_word(similar_word_raw)
	end
	return similar_words
end

---Find the fullsynset and construct and markdown definition string for the provided word. Only include pointers that
---are in the pointer filter.
---@param search_word string
---@param pointer_symbols PointerSymbol[]
---@return string
function M.get_definition_for_word(search_word, pointer_symbols)
	search_word = search_word:lower():gsub(" ", "_")
	local full_synsets = get_full_synsets_for_word(search_word)
	local definition = format.get_definition_string_from_full_synsets(full_synsets, pointer_symbols, search_word)
	return definition
end

return M
