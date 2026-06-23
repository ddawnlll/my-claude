# verify-install.ps1
Write-Host '=== CLAUDE CODE PERSONALIZATION (installed by setup) ===' -ForegroundColor Cyan
Write-Host ''

Write-Host '1. AGENTS (use via /agent in Claude Code):' -ForegroundColor Yellow
$agents = Get-ChildItem "$HOME\.claude\agents\*.md" -ErrorAction SilentlyContinue
if ($agents) { $agents | ForEach-Object { Write-Host "   - $($_.BaseName)" } }

Write-Host ''
Write-Host '2. OUTPUT STYLES (use via /output-style):' -ForegroundColor Yellow
$styles = Get-ChildItem "$HOME\.claude\output-styles\*.md" -ErrorAction SilentlyContinue
if ($styles) { $styles | ForEach-Object { Write-Host "   - $($_.BaseName)" } }

Write-Host ''
Write-Host '3. THEMES (use via /theme):' -ForegroundColor Yellow
$themes = Get-ChildItem "$HOME\.claude\themes\*.json" -ErrorAction SilentlyContinue
if ($themes) { $themes | ForEach-Object { Write-Host "   - $($_.BaseName)" } }

Write-Host ''
Write-Host '4. STATUSLINE:' -ForegroundColor Yellow
if (Test-Path "$HOME\.claude\statusline.sh") { Write-Host '   - statusline.sh (bash script for Claude status bar)' }

Write-Host ''
Write-Host '5. CLAUDE.MD (global coding rules):' -ForegroundColor Yellow
$hasBlock = Select-String -Path "$HOME\.claude\CLAUDE.md" -Pattern 'claude-opencode-go-personalization' -Quiet -ErrorAction SilentlyContinue
if ($hasBlock) { Write-Host '   - Truth-gated coding rules injected' }

Write-Host ''
Write-Host '6. SETTINGS.JSON KEY ENTRIES:' -ForegroundColor Yellow
Write-Host '   - bypassPermissions mode enabled'
Write-Host '   - ANTHROPIC_BASE_URL -> http://127.0.0.1:3456'
Write-Host '   - 5-slot model picker env vars (Fable/Opus/Sonnet/Haiku/Custom)'
Write-Host '   - Cyberpunk theme + Fullscreen TUI'
Write-Host '   - Truth Gated Coder output style'
Write-Host '   - Custom spinner verbs & tips'

Write-Host ''
Write-Host '7. LAUNCHER SCRIPTS (in ~/.local/bin/):' -ForegroundColor Yellow
$launchers = Get-ChildItem "$HOME\.local\bin\*.ps1" -ErrorAction SilentlyContinue
if ($launchers) { $launchers | ForEach-Object { Write-Host "   - $($_.Name)" } }

Write-Host ''
Write-Host '8. OC-GO-CC BINARY:' -ForegroundColor Yellow
$bin = Get-Command oc-go-cc -ErrorAction SilentlyContinue
if ($bin) { Write-Host "   - oc-go-cc.exe installed at: $($bin.Source)" }
else { Write-Host '   - NOT FOUND in PATH' }

Write-Host ''
Write-Host '9. CONFIG VALIDATION:' -ForegroundColor Yellow
$env:OC_GO_CC_API_KEY = 'sk-test'
$valid = & oc-go-cc validate 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Write-Host '   - oc-go-cc validate: PASS' }
else { Write-Host '   - oc-go-cc validate: FAIL (expected if oc-go-cc not running)' }

Write-Host ''
Write-Host '=== CLI COMMANDS TO VERIFY INSIDE CLAUDE CODE ===' -ForegroundColor Cyan
Write-Host '   /agent          (list available agents)'
Write-Host '   /output-style   (list output styles)'
Write-Host '   /theme          (list themes)'
Write-Host '   /statusline     (check status bar)'
Write-Host '   /config         (view settings)'
Write-Host '   /model          (view model picker slots)'
Write-Host ''
Write-Host '=== EXTERNAL TOOLS (check separately) ===' -ForegroundColor Cyan
Write-Host '   claude plugin list         (list installed plugins)'
Write-Host '   claude mcp list            (list MCP servers)'
