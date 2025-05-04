# Workspacesionizer.wezterm

Like [tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles/blob/602019e902634188ab06ea31251c01c1a43d1621/bin/.local/scripts/tmux-sessionizer#L4), from [ThePrimeagen](https://github.com/ThePrimeagen), but for Wezterm workspaces.

![demo](/assets/demo.gif)

> [!IMPORTANT]
> Sorry for the name. :)

# How to use

Inside your Wezterm configs:

1. Load the plugin

```lua
local wpr = wezterm.plugin.require 'https://github.com/vieitesss/workspacesionizer.wezterm'
```

2. Apply the changes to your config using the `apply_to_config` function.

First argument is your own config, created with `wezterm.config_builder()`
Second argument is the plugin configuration with the following specification:

```lua
---@class Sessionizer
---@field paths {string,...} The paths that contains the directories you want to switch into.
---@field git_repos boolean false if you don't want to include the git repositories from your HOME dir in the directories to switch into.
---@field binding Sessionizer.binding

---@class Sessionizer.binding
---@field key string The key to press.
---@field mods string The key to press.
```

A full example:

```lua
wpr.apply_to_config(config, {
    paths = { "~/personal", "~/.config", "~/dev" },
    git_repos = false,
    binding = {
        key = "p",
        mods = "CTRL",
    }
})
```

## Default values

```lua
{
    paths = { wezterm.home_dir },
    git_repos = true,
    binding = {
        key = "o",
        mods = "LEADER",
    },
}
```
