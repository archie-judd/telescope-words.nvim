local fzy = require("fzy")
local format = require("telescope-words.wordnet.format")
local read = require("telescope-words.wordnet.read")
local types = require("telescope-words.wordnet.types")
local utils = require("telescope-words.wordnet.utils")

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
---@param search_word string
---@return FullSynset[]
local function get_full_synsets_for_word(search_word)
	local entries = read.get_exact_index_matches_for_word(search_word)
	utils.sort_index_entries_by_sense_number_and_tag_count(entries)
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
---@return string[]
local function get_similar_words_for_synset(full_synset)
	local similar_words = {}
	for _, word in ipairs(full_synset.words) do
		table.insert(similar_words, word.word)
	end
	for _, full_ptr in ipairs(full_synset.full_pts) do
		if full_ptr.pointer_symbol == "&" or full_ptr.pointer_symbol == "^" then
			for _, word in ipairs(full_ptr.synset.words) do
				table.insert(similar_words, word.word)
			end
			if full_ptr.pointer_symbol == "&" then
				local full_ptr_synset = get_full_synset_for_synset(full_ptr.synset)
				for _, ptr_ptr in ipairs(full_ptr_synset.full_pts) do
					if ptr_ptr.pointer_symbol == "&" then
						for _, word in ipairs(ptr_ptr.synset.words) do
							table.insert(similar_words, word.word)
						end
					end
				end
			end
		end
	end
	return similar_words
end

---Return all the words in the index that starat with the search term
---@param user_query string
---@return string[]
function M.get_fuzzy_word_matches(user_query, char_search_threshold)
	local matches = {}
	local search_term = user_query:lower():gsub(" ", "_")
	local entries_raw = read.get_fuzzy_index_matches_for_word_raw(search_term, char_search_threshold)
	for _, entry_raw in ipairs(entries_raw) do
		local display_word = utils.format_word_for_display(entry_raw:match("^(.-)%%"))
		if fzy.has_match(user_query, display_word) and not utils.array_contains(matches, display_word) then
			table.insert(matches, display_word)
		end
	end
	utils.sort_word_matches_by_fzy_score(matches, user_query)
	return matches
end

---Find the exact word in the index, get the synset, and then find and return all similar words
---@param user_query any
---@return string[]
function M.get_similar_words_for_word(user_query)
	local similar_words = {}
	local search_term = user_query:lower():gsub(" ", "_")
	local full_synsets = get_full_synsets_for_word(search_term)
	local similar_words_raw = {}
	for _, full_synset in ipairs(full_synsets) do
		local _similar_words_raw = get_similar_words_for_synset(full_synset)
		similar_words_raw = utils.join_arrays(similar_words_raw, _similar_words_raw)
	end
	similar_words_raw = utils.remove_duplicates(similar_words_raw)
	similar_words_raw = utils.move_to_start_of_array(similar_words_raw, search_term)
	for i, similar_word_raw in ipairs(similar_words_raw) do
		similar_words[i] = utils.format_word_for_display(similar_word_raw)
	end
	return similar_words
end

---Find the fullsynset and construct and markdown definition string for the provided word. Only include pointers that
---are in the pointer filter.
---@param selected_word string
---@param pointer_symbols PointerSymbol[]
---@return string
function M.get_definition_for_word(selected_word, pointer_symbols)
	selected_word = selected_word:lower():gsub(" ", "_")
	local full_synsets = get_full_synsets_for_word(selected_word)
	local definition = format.get_definition_string_from_full_synsets(full_synsets, pointer_symbols, selected_word)
	return definition
end

return M
