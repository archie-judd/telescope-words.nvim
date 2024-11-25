local M = {}

local DEFAULT_CONFIG = {
	mappings = {},
	layout_config = { width = 0.75, height = 0.75, preview_width = 0.65 },
	layout_strategy = "horizontal",
	pointer_symbols = { "!", "&", "^" },
	fzy_char_threshold = 3,
}

M.config = DEFAULT_CONFIG

---Build a config table for the telescope words plugin -- inherit the global config mappings
---@param ext_config any
---@param global_config any
M.setup_as_extension = function(ext_config, global_config)
	local config = DEFAULT_CONFIG
	if ext_config.char_search_threshold then
		vim.deprecate("char_search_threshold", "fzy_char_threshold", "1.1.0")
		ext_config.fzy_char_threshold = ext_config.char_search_threshold
	end
	config.mappings = vim.tbl_deep_extend("force", config.mappings, global_config.mappings or {})
	config.layout_config = vim.tbl_deep_extend("force", config.layout_config, global_config.layout_config or {})
	config.layout_strategy = global_config.layout_strategy or config.layout_strategy
	config = vim.tbl_deep_extend("force", config, ext_config)
	M.config = config
end

---Build a config table for the telescope words plugin
---@param config table
M.setup = function(config)
	if config.char_search_threshold then
		vim.deprecate("char_search_threshold", "fzy_char_threshold", "1.1.0")
		config.fzy_char_threshold = config.char_search_threshold
	end
	M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config)
end

return M
