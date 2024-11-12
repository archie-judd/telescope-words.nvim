local actions = require("telescope.actions")
local actions_mt = require("telescope.actions.mt")
local actions_state = require("telescope.actions.state")

local M = {}

---Replace the word under the cursor with the selected entry
---@param prompt_bufnr integer
M.replace_word_under_cursor = function(prompt_bufnr)
	actions.close(prompt_bufnr)
	local selection = actions_state.get_selected_entry()
	vim.api.nvim_command("normal ciw" .. selection[1])
	vim.api.nvim_command("stopinsert")
end

M = actions_mt.transform_mod(M)

return M
