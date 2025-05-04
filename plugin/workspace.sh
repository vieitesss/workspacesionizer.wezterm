#!/usr/bin/env bash

if [ -n "$WEZTERM_WORKSPACE" ]; then
	printf "\033]1337;SetUserVar=%s=%s\007" workspace $(echo -n "$WEZTERM_WORKSPACE" | base64)
fi
