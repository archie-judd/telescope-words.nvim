local M = {}

local function add_lua_modules_to_path()
	local filepath = debug.getinfo(1, "S").source:match("@(.*)")
	local plugin_dir = vim.fn.fnamemodify(filepath, ":p:h:h:h")
	local package_path = plugin_dir
		.. "/luarocks/share/lua/5.1/?.lua;"
		.. plugin_dir
		.. "/luarocks/share/lua/5.1/?/init.lua"
	local cpath = plugin_dir .. "luarocks/lib/lua/5.1/?.so"
	package.path = package.path .. ";" .. package_path
	package.cpath = package.cpath .. ";" .. cpath
end

local DEFAULT_CONFIG = {
	mappings = {},
	layout_config = { width = 0.75, height = 0.75, preview_width = 0.65 },
	layout_strategy = "horizontal",
	pointer_symbols = { "!", "&", "^" },
	char_search_threshold = 3,
}

M.config = DEFAULT_CONFIG

---Build a config table for the telescope words plugin -- inherit the global config mappings
---@param ext_config any
---@param global_config any
M.setup_as_extension = function(ext_config, global_config)
	add_lua_modules_to_path()
	local config = DEFAULT_CONFIG
	config.mappings = vim.tbl_deep_extend("force", config.mappings, global_config.mappings or {})
	config.layout_config = vim.tbl_deep_extend("force", config.layout_config, global_config.layout_config or {})
	config.layout_strategy = global_config.layout_strategy or config.layout_strategy
	config = vim.tbl_deep_extend("force", config, ext_config)
	M.config = config
end

---Build a config table for the telescope words plugin
---@param config table
M.setup = function(config)
	add_lua_modules_to_path()
	M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config)
end

return M
