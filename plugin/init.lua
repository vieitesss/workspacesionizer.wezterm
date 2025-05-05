local wezterm = require("wezterm")

---@module Workspacesionizer
---@alias W

local W = {}

---@class W_options
---@field paths table<string> The paths that contains the directories you want to switch into.
---@field git_repos boolean false if you don't want to include the git repositories from your HOME dir in the directories to switch into.
---@field binding W_options_binding

---@class W_options_binding
---@field key string The key to press.
---@field mods string The key to press.

---@type W_options
local W_options = {}

---@return W_options
function W_options:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string The first level of directories inside the paths.
function W_options:list_paths_dirs()
    return exec([[find -L ]] .. table.concat(self.path, ' ') .. [[ -type d -mindepth 1 -maxdepth 1 ]])
end

---@return string All the directories.
function W_options:get_all_dirs()
    ---@type table<string>
    all = {}

    table.insert(all, self:list_paths_dirs())
    if self.git_repos then
        table.insert(all, find_git_repos())
    end

    return table.concat(all)
end

---@return table A table with entries of SpawnCommand.
function W_options:build_entries()
    local entries = {}
    local all = split_lines(self:get_all_dirs())
    local plugin_dir = get_plugin_dir()
    local script = plugin_dir .. "/plugin/workspace.sh"
    for _, dir in ipairs(all) do
        local full = expand_path(dir)
        local basename = full:match("([^/]+)$")
        local workspace = basename:gsub("%.", "_")
        table.insert(entries, {
            label = basename,
            args = { script },
            cwd = full,
            domain = "CurrentPaneDomain",
            set_environment_variables = { WEZTERM_WORKSPACE = workspace },
        })
    end
    return entries
end

---@param path string The path to expand if it starts with tilde.
---@return string The path expanded, if needed.
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
---@return string The output of the command.
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

---@return string The git repos in the home directory separated by line.
local function find_git_repos()
    return exec([[fd -H -d 2 -E "Library" -t d "^\.git$" "$HOME" | sed "s#/\.git/##g"]])
end

---@param s string The string to trim.
---@return string The string trimed.
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@return string The absolute path to de plugin.
local function get_plugin_dir()
    for _, p in ipairs(wezterm.plugin.list()) do
        if p.url:match("workspacesionizer") then
            return p.plugin_dir:gsub("/+$", "")
        end
    end
    return wezterm.home_dir
end

---@param s string The string to split into lines.
---@return table A table with all the lines from the string.
local function split_lines(s)
    local t = {}
    for line in s:gmatch("([^\r\n]+)") do
        table.insert(t, line)
    end
    return t
end

local _options = W_options:new({
    paths = { wezterm.home_dir },
    git_repos = true,
    binding = {
        key = "o",
        mods = "LEADER",
    },
})

---@param config table
---@param options W_options
W.apply_to_config = function(config, options)
    if options.paths or options.paths ~= nil then
        _options.paths = {}
        for _, p in ipairs(options.paths) do
            table.insert(_options.paths, expand_path(p))
        end
    end

    _options.git_repos = options.git_repos ~= false

    if options.binding then
        if options.binding.key and options.binding.mods then
            _options.binding = options.binding
        end
    end

    config.launch_menu = _options:build_entries()

    table.insert(config.keys, {
        key = _options.binding.key,
        mods = _options.binding.mods,
        action = wezterm.action.ShowLauncherArgs {
            flags = "FUZZY|LAUNCH_MENU_ITEMS",
        },
    })

    wezterm.on("user-var-changed", function(window, pane, name, value)
        wezterm.log_info(string.format("var changed: %s -> %s", name, value))
        if name == "workspace" and value and value ~= "" then
            window:perform_action(
                wezterm.action.SwitchToWorkspace { name = value },
                pane
            )
        end
    end)
end

return W
