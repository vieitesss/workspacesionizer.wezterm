local wezterm = require("wezterm")

local M = {}

---@class Sessionizer
---@field paths {string,...} The paths that contains the directories you want to switch into.
---@field git_repos boolean false if you don't want to include the git repositories from your HOME dir in the directories to switch into.
---@field binding Sessionizer.binding

---@class Sessionizer.binding
---@field key string The key to press.
---@field mods string The key to press.

---@type Sessionizer
local _options = {
    paths = { wezterm.home_dir },
    git_repos = true,
    binding = {
        key = "o",
        mods = "LEADER",
    },
}

local function expand_path(path)
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
---@return string The output
local function exec(cmd)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    local success, exit_type, code = handle:close()

    if success then
        return output
    else
        return string.format("The command failed (%s, code %d)\n", exit_type, code)
    end
end

_options.list_paths_dirs = function()
    return exec([[find -L ]] .. table.concat(_options.paths, ' ') .. [[ -type d -mindepth 1 -maxdepth 1 ]])
end

local function find_git_repos()
    return exec([[fd -H -d 2 -E "Library" -t d "^\.git$" "$HOME" | sed "s#/\.git/##g"]])
end

---@return table
_options.get_all_dirs = function()
    all_dirs = {}

    for _, value in ipairs(_options.paths) do
        for _, d in ipairs(M.list_dirs(value)) do
            table.insert(all_dirs, d)
        end
    end

    for _, d in ipairs(M.find_git_repos()) do
        table.insert(all_dirs, d)
    end

    return all_dirs
end

local function execute(cmd)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    local success, exit_type, code = handle:close()

    if success then
        return output
    end

    return ""
end

M.select_workspace = function()
    local dirs = M.get_all_dirs()
    local selected = execute([[echo "]] ..
        table.concat(dirs, "\n") ..
        [[" | fzf --layout=reverse --preview-window down --preview "eza --color=always -l {}"]])
    return selected
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param config table
M.change_workspace = function(config)
    local selected = M.select_workspace()
    if not selected or selected == "" then
        return
    end

    selected = trim(selected)
    local basename = selected:match("([^/]+)$")
    local workspace = basename:gsub("%.", "_")

    table.insert(config.keys, {
        key = _options.binding.key,
        mods = _options.binding.mods,
        action = wezterm.action.SwitchToWorkspace {
            name = workspace,
        },
    })
end

---@param config table
---@param options Sessionizer
---@return string output
M.apply_to_config = function(config, options)
    if options.paths or options.paths ~= nil then
        _options.paths = {}
        for _, p in ipairs(options.paths) do
            table.insert(_options.paths, expand_path(p))
        end
    end

    _options.git_repos = (not (options.git_repos == false)) or _options.git_repos

    local out = {}
    if _options.git_repos then
        table.insert(out, find_git_repos())
    end

    table.insert(out, _options.list_paths_dirs())
    return table.concat(out, '')
end


return M
