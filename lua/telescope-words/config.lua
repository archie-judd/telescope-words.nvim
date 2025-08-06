local M = {}

--- @class TelescopeWordsConfig
--- @field definition_pointers string[] Symbols used to indicate pointers in the preview
--- @field pointer_symbols? string[] @deprecated Use definition_pointers instead
--- @field fzy_char_threshold integer | nil @deprecated Use dictionary_search_threshold instead
--- @field dictionary_search_threshold integer Minimum length of a word to search in the dictionary
--- @field similarity_pointers string[] Pointers to consider for similarity in thesaurus
--- @field similarity_depth integer Depth of similarity search in thesaurus
--- @field mappings table Key mappings for the telescope words plugin
--- @field layout_config table Layout configuration for the telescope words plugin
--- @field layout_strategy string Layout strategy for the telescope words plugin
local DEFAULT_CONFIG = {
	pointer_symbols = nil,
	fzy_char_threshold = nil,
	definition_pointers = { "!", "&", "^" },
	dictionary_search_threshold = 3,
	similarity_pointers = { "&", "^" },
	similarity_depth = 2,
	layout_strategy = "horizontal",
	layout_config = {},
	mappings = {},
}

M.config = DEFAULT_CONFIG

---Build a config table for the telescope words plugin -- inherit the global config mappings
---@param ext_config TelescopeWordsConfig
---@param global_config any
M.setup_as_extension = function(ext_config, global_config)
	ext_config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, ext_config or {})
	vim.validate(
		"telescope-words.ext_config.dictionary_search_threshold",
		ext_config.dictionary_search_threshold,
		{ "number" }
	)
	vim.validate("telescope-words.ext_config.defintion_pointers", ext_config.definition_pointers, { "table" })
	vim.validate("telescope-words.ext_config.similarity_pointers", ext_config.similarity_pointers, { "table" })
	vim.validate("telescope-words.ext_config.similarity_depth", ext_config.similarity_depth, { "number" })
	vim.validate("telescope-words.ext_config.layout_strategy", ext_config.layout_strategy, { "string" })
	vim.validate("telescope-words.ext_config.layout_config", ext_config.layout_config, { "table" })
	if ext_config.fzy_char_threshold then
		vim.deprecate("fzy_char_threshold", "dictionary_search_threshold", "2.1.0", "telescope-words")
	end
	ext_config.dictionary_search_threshold = ext_config.dictionary_search_threshold or ext_config.fzy_char_threshold
	if ext_config.pointer_symbols then
		vim.deprecate("pointer_symbols", "definition_pointers", "2.1.0", "telescope-words")
		ext_config.definition_pointers = ext_config.definition_pointers or ext_config.pointer_symbols
	end

	ext_config.mappings = vim.tbl_deep_extend("force", ext_config.mappings, global_config.mappings or {})
	ext_config.layout_config = vim.tbl_deep_extend("force", ext_config.layout_config, global_config.layout_config or {})
	ext_config.layout_strategy = ext_config.layout_strategy or global_config.layout_strategy
	M.config = vim.tbl_deep_extend("force", global_config, ext_config)
end

return M
