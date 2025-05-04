dir := shell('fd -t d "^files.*workspace.*" ~/Library/Application\ Support/wezterm/plugins/')

_default:
  just -l

up:
  git commit -a -m "$(date)"
  git push prueba main
  rm -rf {{dir}} || true

run:
  wezterm
