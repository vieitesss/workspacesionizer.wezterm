dir := shell('fd -t d "^files.*workspace.*" ~/Library/Application\ Support/wezterm/plugins/')

_default:
  just -l

c:
  git commit -a -m "$(date)"

r:
  rm -rf "{{dir}}" || true
  wezterm

res:
  git reset --soft HEAD~1
  git restore --staged .
