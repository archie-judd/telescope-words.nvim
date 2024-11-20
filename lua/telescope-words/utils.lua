local M = {}
function M.add_lua_modules_to_path()
	local filepath = debug.getinfo(1, "S").source:match("@(.*)")
	local plugin_dir = vim.fn.fnamemodify(filepath, ":p:h:h:h")
	local package_path = plugin_dir
		.. "/lua_modules/share/lua/5.1/?.lua;"
		.. plugin_dir
		.. "/lua_modules/share/lua/5.1/?/init.lua"
	local cpath = plugin_dir .. "lua_modules/lib/lua/5.1/?.so"
	package.path = package.path .. ";" .. package_path
	package.cpath = package.cpath .. ";" .. cpath
end
return M
