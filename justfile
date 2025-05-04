dir := shell('fd -t d "^files.*workspace.*" ~/Library/Application\ Support/wezterm/plugins/')

_default:
  just -l

up:
  rm -rf {{dir}} || true
  git commit -a -m "$(date)"

run:
  wezterm

res:
  git reset --soft HEAD~1
  git restore --staged .
