dir := shell('fd -t d "^files.*workspace.*" ~/Library/Application\ Support/wezterm/plugins/')

_default:
  just -l

run:
  rm -rf {{dir}} || true
  wezterm

try:
  @echo "rm -rf {{dir}}"
  @echo "wezterm"
