local wezterm = require 'wezterm'

local separator = package.config:sub(1, 1) == "\\" and "\\" or "/"
local plugin_dir = wezterm.plugin.list()[1].plugin_dir:gsub(separator .. "[^" .. separator .. "]*$", "")

--- Checks if the plugin directory exists
local function directory_exists(path)
    local success, result = pcall(wezterm.read_dir, plugin_dir .. path)
    return success and result
end

--- Returns the name of the package, used when requiring modules
local function get_require_path()
    local path = "httpssCssZssZsgithubsDscomsZsvieitessssZsworkspacesionizersDswezterm"
    local path_trailing_slash = "httpssCssZssZsgithubsDscomsZsvieitessssZsworkspacesionizersDsweztermZs"
    return directory_exists(path_trailing_slash) and path_trailing_slash or path
end

package.path = package.path
    .. ";"
    .. plugin_dir
    .. separator
    .. get_require_path()
    .. separator
    .. "plugin"
    .. separator
    .. "?.lua"

local utils = require 'utils'

---@module Workspacesionizer
---@alias W

local W = {}

---@class W_options
---@field paths string[] The paths that contains the directories you want to switch into.
---@field git_repos boolean false if you don't want to include the git repositories from your HOME dir in the directories to switch into.
---@field show "base" | "full" Wether to show directories base or full name.
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
    return utils.exec([[find -L ]] .. table.concat(self.paths, ' ') .. [[ -type d -mindepth 1 -maxdepth 1 ]])
end

---@return string All the directories.
function W_options:get_all_dirs()
    ---@type string[]
    all = {}

    table.insert(all, self:list_paths_dirs())
    if self.git_repos then
        table.insert(all, utils.find_git_repos())
    end

    return table.concat(all)
end

-- ---@return table A table with entries of SpawnCommand.
-- function W_options:build_entries()
--     local entries = {}
--     local all = utils.split_lines(self:get_all_dirs())
--     local plugin_dir = utils.get_plugin_dir()
--     local script = plugin_dir .. "/plugin/workspace.sh"
--     for _, dir in ipairs(all) do
--         local full = utils.expand_path(dir)
--         local basename = full:match("([^/]+)$")
--         local workspace = basename:gsub("[%.%-]", "_")
--         local label = full
--         if self.show == "base" then
--             label = workspace
--         end
--         table.insert(entries, {
--             label = label,
--             args = { script },
--             cwd = full,
--             domain = "CurrentPaneDomain",
--             set_environment_variables = { WEZTERM_WORKSPACE = workspace },
--         })
--     end
--     return entries
-- end

function W_options:build_entries()
    local entries = {}
    local dirs = utils.split_lines(self:get_all_dirs())

    for _, d in ipairs(dirs) do

        local label = d
        if self.show == "base" then
            label = d:match("([^/]+)$")
        end

        table.insert(entries, {
            id = d,
            label = label,
        })
    end

end

local _options = W_options:new({
    paths = { wezterm.home_dir },
    git_repos = true,
    show = "full",
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
            table.insert(_options.paths, utils.expand_path(p))
        end
    end

    _options.git_repos = options.git_repos ~= false

    if options.binding then
        if options.binding.key and options.binding.mods then
            _options.binding = options.binding
        end
    end

    _options.show = options.show or _options.show

    table.insert(config.keys, {
        key = _options.binding.key,
        mods = _options.binding.mods,
        action = wezterm.action_callback(function(window, pane)
            local choices = _options:build_entries()

            window:perform_action(
                act.InputSelector {
                    action = wezterm.action_callback(function(window, pane, id, label)
                        if not id and not label then
                            wezterm.log_info 'cancelled'
                        else
                            wezterm.log_info('you selected ', id, label)
                            window:perform_action(
                                wezterm.action.SwitchToWorkspace { name = value },
                                pane
                            )
                        end
                    end),
                    title = 'Select a workspace',
                    choices = choices,
                    fuzzy = true,
                    fuzzy_description = 'Fuzzy find and/or make a workspace',
                },
                pane
            )
        end),
    })

    return config
end

return W
