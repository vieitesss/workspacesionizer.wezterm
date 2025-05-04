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
    paths = {},
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

M.list_dirs = function()
    return wezterm.run_child_process({ 'fd', '.', '~/personal' })
end

M.find_git_repos = function()
    -- local home = os.getenv("HOME")
    -- local repos = {}
    --
    -- local function scan(dir, depth)
    --     if depth >= 2 then return end
    --     for name in lfs.dir(dir) do
    --         if name ~= "." and name ~= ".." and name ~= ".Trash" and name ~= "Library" then
    --             local full = dir .. "/" .. name
    --             local mode = lfs.symlinkattributes(full, "mode")
    --             if mode == "directory" then
    --                 if name == ".git" then
    --                     table.insert(repos, dir)
    --                 else
    --                     scan(full, depth + 1)
    --                 end
    --             end
    --         end
    --     end
    -- end
    --
    -- scan(home, 0)
    -- return repos
end

---@return table
M.get_all_dirs = function()
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
M.apply_to_config = function(config, options)
    if options.paths or options.paths ~= nil then
        _options.paths = options.paths
    end

    M.change_workspace(config)
end

M.list_dirs()

return M
