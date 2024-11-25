require("telescope-words.bootstrap")
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
---@param pointer_symbols string[]
---@return string
local function get_definition_safe(user_query, pointer_symbols)
	local success, results_or_error = pcall(wordnet.get_definition_for_word, user_query, pointer_symbols)
	if success then
		return results_or_error
	else
		vim.notify("Error: " .. results_or_error, vim.log.levels.ERROR)
		return ""
	end
end

---Get the dictionary entries for a term, catching and logging any errors
---@param user_query string
---@param fzy_char_threshold integer
---@return string[]
local function search_dictionary_safe(user_query, fzy_char_threshold)
	if user_query == "" then
		return {}
	end
	fzy_char_threshold = math.max(fzy_char_threshold, 1)
	local success, results_or_error = pcall(wordnet.get_word_matches, user_query, fzy_char_threshold)
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
local function search_thesaurus_safe(user_query)
	if user_query == "" then
		return {}
	end
	local success, results_or_error = pcall(wordnet.get_similar_words_for_word, user_query)
	if success then
		return results_or_error
	else
		vim.notify("Error: " .. results_or_error, vim.log.levels.ERROR)
		return {}
	end
end

---Merge the provided opts table with the config table
---@param opts table
---@param config table
---@return table
local function merge_opts_with_config(opts, config)
	if opts.char_search_threshold then
		vim.deprecate("char_search_threshold", "fzy_char_threshold", "1.1.0")
		opts.fzy_char_threshold = opts.char_search_threshold
	end
	opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, config.mappings or {})
	opts.layout_config = vim.tbl_deep_extend("force", opts.layout_config or {}, config.layout_config or {})
	opts.pointer_symbols = opts.pointer_symbols or config.pointer_symbols
	opts.layout_strategy = opts.layout_strategy or config.layout_strategy
	opts.fzy_char_threshold = opts.fzy_char_threshold or config.fzy_char_threshold
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
	local definition = get_definition_safe(entry[1], opts.pointer_symbols)
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
					return search_dictionary_safe(user_query, opts.fzy_char_threshold)
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
				fn = search_thesaurus_safe,
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
					return search_dictionary_safe(user_query, opts.fzy_char_threshold)
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
				fn = search_thesaurus_safe,
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

M.setup = function(opts)
	telescope_word_config.setup(opts)
end

return M
