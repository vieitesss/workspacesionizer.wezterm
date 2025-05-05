local wezterm = require 'wezterm'

local M = {}

---@param path string The path to expand if it starts with tilde.
---@return string The path expanded, if needed.
M.expand_path = function(path)
    if path:sub(1, 1) == "~" then
        local home = wezterm.home_dir
        if path == "~" then
            return home
        elseif path:sub(2, 3) == "/ " or path:sub(2, 2) == "/" then
            return home .. path:sub(2)
        end
    end
    return path
end

---@param cmd string The command to execute.
---@return string The output of the command.
M.exec = function(cmd)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    local success, exit_type, code = handle:close()

    if success then
        return output
    else
        return string.format("The command failed (%s, code %d)\n", exit_type, code)
    end
end

---@return string The git repos in the home directory separated by line.
M.find_git_repos = function()
    return M.exec([[find "$HOME" -maxdepth 2 \( -path "$HOME/Library" -o -path "$HOME/.Trash" \) -prune -o -type d -name ".git" -print]])
end

---@param s string The string to trim.
---@return string The string trimed.
M.trim = function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@return string The absolute path to de plugin.
M.get_plugin_dir = function()
    for _, p in ipairs(wezterm.plugin.list()) do
        if p.url:match("workspacesionizer") then
            return p.plugin_dir:gsub("/+$", "")
        end
    end
    return wezterm.home_dir
end

---@param s string The string to split into lines.
---@return table A table with all the lines from the string.
M.split_lines = function(s)
    local t = {}
    for line in s:gmatch("([^\r\n]+)") do
        table.insert(t, line)
    end
    return t
end

return M
