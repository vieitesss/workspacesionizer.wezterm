#!/usr/bin/env bash

if [ -n "$WEZTERM_WORKSPACE" ]; then
  printf "\033]1337;SetUserVar=workspace=%s\007" "$WEZTERM_WORKSPACE"
fi

exec "$SHELL"
