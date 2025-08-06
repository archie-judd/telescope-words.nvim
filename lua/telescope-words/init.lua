local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewer_utils = require("telescope.previewers.utils")
local previewers = require("telescope.previewers")
local telescope_word_config = require("telescope-words.config")
local wordnet = require("telescope-words.wordnet")

local M = {}

---Get the definition for a word, catching and logging any errors
---@param user_query string
---@param definition_pointers string[]
---@return string
local function get_definition_safe(user_query, definition_pointers)
	local success, results_or_error = pcall(wordnet.get_definition_for_word, user_query, definition_pointers)
	if success then
		return results_or_error
	else
		vim.notify("Error: " .. results_or_error, vim.log.levels.ERROR)
		return ""
	end
end

---Get the dictionary entries for a term, catching and logging any errors
---@param user_query string
---@param dictionary_search_threshold integer
---@return string[]
local function search_dictionary_safe(user_query, dictionary_search_threshold)
	if user_query == "" then
		return {}
	end
	dictionary_search_threshold = math.max(dictionary_search_threshold, 1)
	local success, results_or_error = pcall(wordnet.get_word_matches, user_query, dictionary_search_threshold)
	if success then
		return results_or_error
	else
		vim.notify("Error: " .. results_or_error, vim.log.levels.ERROR)
		return {}
	end
end

---Get the thesaurus entries for a word, catching and logging any errors
---@param user_query string
---@return string[]
local function search_thesaurus_safe(user_query, dictionary_search_threshold, similarity_pointers, similarity_depth)
	if user_query == "" then
		return {}
	end
	local success, results_or_error = pcall(
		wordnet.get_similar_words_for_word,
		user_query,
		dictionary_search_threshold,
		similarity_pointers,
		similarity_depth
	)
	if success then
		return results_or_error
	else
		vim.notify("Error: " .. results_or_error, vim.log.levels.ERROR)
		return {}
	end
end

---Merge the provided opts table with the config table
---@param opts TelescopeWordsConfig
---@param config table
---@return table
local function merge_opts_with_config(opts, config)
	opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, config.mappings or {})
	opts.layout_config = vim.tbl_deep_extend("force", opts.layout_config or {}, config.layout_config or {})
	opts.layout_strategy = opts.layout_strategy or config.layout_strategy
	opts.dictionary_search_threshold = opts.dictionary_search_threshold or config.dictionary_search_threshold
	opts.similarity_pointers = opts.similarity_pointers or config.similarity_pointers
	opts.similarity_depth = opts.similarity_depth or config.similarity_depth
	opts.definition_pointers = opts.definition_pointers or config.definition_pointers
	opts.similarity_depth = opts.similarity_depth or config.similarity_depth
	return opts
end

---Replace the select_default action with a custom action that enters the selected entry in the buffer. Also register
---any mappings from opts.
---@param prompt_bufnr integer
---@param map function
---@param opts table
local function attach_mappings(prompt_bufnr, map, opts)
	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		vim.api.nvim_put({ selection[1] }, "c", true, true)
	end)
	if opts.mappings and opts.mappings.i then
		for key, func in pairs(opts.mappings.i) do
			map("i", key, func)
		end
	end
	if opts.mappings and opts.mappings.n then
		for key, func in pairs(opts.mappings.n) do
			map("n", key, func)
		end
	end
end

---Construct the preview string and configure the preview window
---@param self table
---@param entry table
---@param status table
---@param opts table
local function define_preview(self, entry, status, opts)
	local definition = get_definition_safe(entry[1], opts.definition_pointers)
	local line_table = vim.split(definition, "\n", { trimempty = false })
	vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, line_table)
	vim.api.nvim_win_set_option(status.preview_win, "wrap", true)
	vim.api.nvim_win_set_option(status.preview_win, "conceallevel", 2)
	vim.api.nvim_win_set_option(status.preview_win, "number", false)
	previewer_utils.highlighter(self.state.bufnr, "markdown")
end

---Search for telescope-words.wordnet.matches using telescope
---@param opts table
M.search_dictionary = function(opts)
	opts = opts or {}
	opts = merge_opts_with_config(opts, telescope_word_config.config)

	pickers
		.new(opts, {
			prompt_title = "Dictionary",
			results_title = "Words",
			finder = finders.new_dynamic({
				fn = function(user_query)
					return search_dictionary_safe(user_query, opts.dictionary_search_threshold)
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "WordNet Definition",
				define_preview = function(self, entry, status)
					define_preview(self, entry, status, opts)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				attach_mappings(prompt_bufnr, map, opts)
				return true
			end,
			layout_strategy = opts.layout_strategy,
			layout_config = opts.layout_config,
		})
		:find()
end

---Find the exact match for the telescope entry, and then find and return all similar words
---@param opts table
M.search_thesaurus = function(opts)
	opts = opts or {}
	opts = merge_opts_with_config(opts, telescope_word_config.config)

	pickers
		.new(opts, {
			prompt_title = "Thesaurus",
			results_title = "Similar words",
			finder = finders.new_dynamic({
				fn = function(user_query)
					return search_thesaurus_safe(
						user_query,
						opts.dictionary_search_threshold,
						opts.similarity_pointers,
						opts.similarity_depth
					)
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "WordNet Definition",
				define_preview = function(self, entry, status)
					define_preview(self, entry, status, opts)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				attach_mappings(prompt_bufnr, map, opts)
				return true
			end,
			layout_strategy = opts.layout_strategy,
			layout_config = opts.layout_config,
		})
		:find()
end

---Search for wordnet matches for the word under the cursor using telescope
---@param opts table
M.search_dictionary_for_word_under_cursor = function(opts)
	opts = opts or {}
	opts = merge_opts_with_config(opts, telescope_word_config.config)

	pickers
		.new(opts, {
			prompt_title = "Dictionary",
			results_title = "Words",
			finder = finders.new_dynamic({
				fn = function(user_query)
					return search_dictionary_safe(user_query, opts.dictionary_search_threshold)
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "WordNet Definition",
				define_preview = function(self, entry, status)
					define_preview(self, entry, status, opts)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				attach_mappings(prompt_bufnr, map, opts)
				actions.insert_original_cword(prompt_bufnr)
				return true
			end,
			layout_strategy = opts.layout_strategy,
			layout_config = opts.layout_config,
		})
		:find()
end

---Find the exact match for the word under the cursor, and then find and return all similar words
---@param opts table
M.search_thesaurus_for_word_under_cursor = function(opts)
	opts = opts or {}
	opts = merge_opts_with_config(opts, telescope_word_config.config)

	pickers
		.new(opts, {
			prompt_title = "Thesaurus",
			results_title = "Similar words",
			finder = finders.new_dynamic({
				fn = function(user_query)
					return search_thesaurus_safe(
						user_query,
						opts.dictionary_search_threshold,
						opts.similarity_pointers,
						opts.similarity_depth
					)
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "WordNet Definition",
				define_preview = function(self, entry, status)
					define_preview(self, entry, status, opts)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				attach_mappings(prompt_bufnr, map, opts)
				actions.insert_original_cword(prompt_bufnr)
				return true
			end,
			layout_strategy = opts.layout_strategy,
			layout_config = opts.layout_config,
		})
		:find()
end

return M
