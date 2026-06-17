#!/usr/bin/env pwsh
# setup-claude-opencode-go-personalized.ps1
#
# PowerShell port of setup-claude-opencode-go-personalized.sh
#
# One-shot installer/configurator for:
#   Claude Code / Claude Desktop -> oc-go-cc -> OpenCode Go
#
# What it does:
#   1) Clones https://github.com/ddawnlll/oc-go-cc into ~/.local/src/oc-go-cc
#      (or updates the existing checkout) and runs `make build` to produce the binary
#   2) Installs the resulting binary to ~/.local/bin/oc-go-cc
#   3) Saves your OpenCode Go API key privately at ~/.config/oc-go-cc/env.ps1
#   4) Fetches the live OpenCode Go model list
#   5) Writes ~/.config/oc-go-cc/config.json
#   6) Writes/repairs ~/.claude/settings.json
#   7) Installs global Claude Code personalization layer:
#        - permissive bypassPermissions mode
#        - truth-gated coder output style
#        - global CLAUDE.md coding rules
#        - global subagents: architect-reviewer, typescript-pro, react-specialist,
#          test-automator, debugger, code-reviewer
#        - cyberpunk theme + fullscreen TUI + animated spinner verbs/tips
#        - custom statusline (uses python3 to render)
#   8) Creates launcher scripts (.ps1):
#        start-oc-go-cc.ps1
#        claude-ocgo.ps1
#        claude-truth.ps1
#        ocgo-routing-doctor.ps1
#
# Usage:
#   .\setup-claude-opencode-go-personalized.ps1 -Key "sk-opencode-your-key"
#
# Or:
#   $env:OC_GO_CC_API_KEY = "sk-opencode-your-key"
#   .\setup-claude-opencode-go-personalized.ps1

param(
    [Alias('k')]
    [string]$Key,

    [Alias('force')]
    [switch]$ForceInstall,

    [Alias('skip')]
    [switch]$SkipInstall,

    [Alias('deepseek')]
    [switch]$DeepseekOnly,

    [Alias('src')]
    [string]$SourceDir,

    [string]$Branch,

    [Alias('noUpdate')]
    [switch]$NoUpdateSource,

    [Alias('h')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# ─── Defaults ────────────────────────────────────────────────────────────────
$Script:OC_GO_CC_REPO_URL = "https://github.com/ddawnlll/oc-go-cc.git"
$Script:OC_GO_CC_REPO_BRANCH = if ($Branch) { $Branch } else { "main" }
$Script:OC_GO_CC_SOURCE_DIR = if ($SourceDir) { $SourceDir } else { "$HOME\.local\src\oc-go-cc" }
$Script:INSTALL_DIR = "$HOME\.local\bin"
$Script:OC_CONFIG_DIR = "$HOME\.config\oc-go-cc"
$Script:CLAUDE_DIR = "$HOME\.claude"

$Script:KEY = if ($Key) { $Key } else { $env:OC_GO_CC_API_KEY }

# ─── Helper functions ────────────────────────────────────────────────────────
function Write-Info  { Write-Host "INFO: $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "OK: $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "WARN: $args" -ForegroundColor Yellow }
function Write-Fail  { Write-Host "ERROR: $args" -ForegroundColor Red; exit 1 }

function Show-Help {
    @"
Usage:
  .\setup-claude-opencode-go-personalized.ps1 -Key "sk-opencode-your-key"

Options:
  -Key VALUE              OpenCode Go API key. You can also set `$env:OC_GO_CC_API_KEY.
  -ForceInstall           Rebuild and reinstall oc-go-cc from Mehmet's fork.
  -SkipInstall            Do not clone/build/install; only write configs.
  -DeepseekOnly           Configure only deepseek-v4-flash with high thinking.
  -SourceDir PATH         Override oc-go-cc source checkout path.
                          (default: `$HOME\.local\src\oc-go-cc, env: OC_GO_CC_SOURCE_DIR)
  -Branch NAME            Override git branch for the fork. (default: main)
  -NoUpdateSource         Do not git fetch/reset existing source checkout; just build current.
  -Help                   Show help.

Source repo:
  https://github.com/ddawnlll/oc-go-cc
  Cloned and built with 'make build' from the fork — no upstream release binary.

After install:
  start-oc-go-cc.ps1

In another terminal:
  claude-ocgo.ps1

Inside Claude Code:
  /clear opencode-go-test
  /model

Model aliases:
  Get-Content ~\.claude\opencode-go-models.txt

Verify routing:
  ocgo-routing-doctor.ps1
"@
    exit 0
}

if ($Help) { Show-Help }

# ─── Prerequisites ───────────────────────────────────────────────────────────
# Check Python availability - avoid Microsoft Store stub
$pythonCheck = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCheck -or $pythonCheck.Source -match 'WindowsApps') {
    # Try python3
    $pythonCheck = Get-Command python3 -ErrorAction SilentlyContinue
}
if (-not $pythonCheck -or $pythonCheck.Source -match 'WindowsApps') {
    # Try known Python installation paths
    $knownPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    )
    $found = $false
    foreach ($p in $knownPaths) {
        if (Test-Path $p) { $found = $true; break }
    }
    if (-not $found) {
        Write-Fail "python or python3 is required. Install from python.org and ensure it's on PATH."
    }
}
if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
    Write-Fail "curl is required"
}

function Require-SourceBuildTools {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail "git is required to clone $OC_GO_CC_REPO_URL. Install git."
    }
    if (-not (Get-Command make -ErrorAction SilentlyContinue)) {
        Write-Fail "make is required to build oc-go-cc from source. Install make / build-essential."
    }
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Fail "go is required to build oc-go-cc from source. Install Go (>= 1.22)."
    }
}

# Detect python executable - avoid Microsoft Store stub
$Script:PYTHON_EXE = "python"
$py3 = Get-Command python3 -ErrorAction SilentlyContinue
if ($py3 -and $py3.Source -notmatch 'WindowsApps') {
    $Script:PYTHON_EXE = "python3"
} else {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py -and $py.Source -notmatch 'WindowsApps') {
        $Script:PYTHON_EXE = "python"
    } elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe") {
        $Script:PYTHON_EXE = "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe"
    } elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe") {
        $Script:PYTHON_EXE = "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe"
    } elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe") {
        $Script:PYTHON_EXE = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    }
}

# ─── Ensure directories ──────────────────────────────────────────────────────
$null = New-Item -ItemType Directory -Force -Path $INSTALL_DIR
$null = New-Item -ItemType Directory -Force -Path $OC_CONFIG_DIR
$null = New-Item -ItemType Directory -Force -Path $CLAUDE_DIR

# ─── Install oc-go-cc from source ────────────────────────────────────────────
function Install-OcGoCcFromSource {
    $target = "$INSTALL_DIR\oc-go-cc.exe"
    $parent = Split-Path $OC_GO_CC_SOURCE_DIR -Parent
    $null = New-Item -ItemType Directory -Force -Path $parent
    $null = New-Item -ItemType Directory -Force -Path $INSTALL_DIR

    Require-SourceBuildTools

    if (-not (Test-Path "$OC_GO_CC_SOURCE_DIR\.git")) {
        Write-Info "Cloning $OC_GO_CC_REPO_URL (branch $OC_GO_CC_REPO_BRANCH) into $OC_GO_CC_SOURCE_DIR ..."
        if (Test-Path $OC_GO_CC_SOURCE_DIR) {
            Remove-Item -Recurse -Force $OC_GO_CC_SOURCE_DIR
        }
        git clone --branch $OC_GO_CC_REPO_BRANCH $OC_GO_CC_REPO_URL $OC_GO_CC_SOURCE_DIR
        if (-not $?) { Write-Fail "git clone failed" }
    }
    elseif ($NoUpdateSource) {
        Write-Info "Using existing source checkout at $OC_GO_CC_SOURCE_DIR (-NoUpdateSource)."
    }
    else {
        Write-Info "Updating existing source checkout at $OC_GO_CC_SOURCE_DIR ..."
        $originUrl = & git -C $OC_GO_CC_SOURCE_DIR remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0 -or $originUrl -notmatch [regex]::Escape($OC_GO_CC_REPO_URL)) {
            Write-Warn "Source dir exists but its origin is not $OC_GO_CC_REPO_URL."
            Write-Warn "Re-cloning to ensure binary comes from Mehmet's fork."
            Remove-Item -Recurse -Force $OC_GO_CC_SOURCE_DIR
            git clone --branch $OC_GO_CC_REPO_BRANCH $OC_GO_CC_REPO_URL $OC_GO_CC_SOURCE_DIR
            if (-not $?) { Write-Fail "git clone failed" }
        }
        else {
            & git -C $OC_GO_CC_SOURCE_DIR fetch origin $OC_GO_CC_REPO_BRANCH
            & git -C $OC_GO_CC_SOURCE_DIR reset --hard "origin/$OC_GO_CC_REPO_BRANCH"
            & git -C $OC_GO_CC_SOURCE_DIR clean -fdx
        }
    }

    Write-Info "Running 'make build' in $OC_GO_CC_SOURCE_DIR ..."
    Push-Location $OC_GO_CC_SOURCE_DIR
    try {
        & make build
        if (-not $?) { Write-Fail "make build failed" }
    }
    finally {
        Pop-Location
    }

    # Find the built binary
    $candidates = @(
        "$OC_GO_CC_SOURCE_DIR\oc-go-cc",
        "$OC_GO_CC_SOURCE_DIR\oc-go-cc.exe",
        "$OC_GO_CC_SOURCE_DIR\bin\oc-go-cc",
        "$OC_GO_CC_SOURCE_DIR\bin\oc-go-cc.exe",
        "$OC_GO_CC_SOURCE_DIR\build\oc-go-cc",
        "$OC_GO_CC_SOURCE_DIR\build\oc-go-cc.exe",
        "$OC_GO_CC_SOURCE_DIR\dist\oc-go-cc",
        "$OC_GO_CC_SOURCE_DIR\dist\oc-go-cc.exe",
        "$OC_GO_CC_SOURCE_DIR\cmd\oc-go-cc\oc-go-cc",
        "$OC_GO_CC_SOURCE_DIR\cmd\oc-go-cc\oc-go-cc.exe"
    )

    $built = $null
    foreach ($cand in $candidates) {
        if (Test-Path $cand -PathType Leaf) {
            $built = $cand
            break
        }
    }

    if (-not $built) {
        $foundFiles = Get-ChildItem $OC_GO_CC_SOURCE_DIR -Recurse -Filter "oc-go-cc*" -File `
            | Where-Object { $_.DirectoryName -notmatch '\\.git\\' -and ($_.Extension -eq '' -or $_.Extension -eq '.exe') }
        if ($foundFiles) {
            $built = $foundFiles | Sort-Object FullName | Select-Object -First 1 -ExpandProperty FullName
        }
    }

    if (-not $built) {
        Write-Fail "make build completed but no oc-go-cc executable was found. Check $OC_GO_CC_SOURCE_DIR"
    }

    Write-Ok "Built binary: $built"
    Copy-Item -Force $built $target
    Write-Ok "Installed oc-go-cc to $target"

    $commit = & git -C $OC_GO_CC_SOURCE_DIR rev-parse --short HEAD 2>$null
    if (-not $commit) { $commit = "unknown" }
    Write-Ok "Source commit: $commit"

    # Add to PATH for current session
    $env:PATH = "$INSTALL_DIR;$env:PATH"

    if (Get-Command oc-go-cc -ErrorAction SilentlyContinue) {
        Write-Ok "Active oc-go-cc: $(Get-Command oc-go-cc)"
    }
    else {
        Write-Warn "oc-go-cc installed but not found in current PATH. Add $INSTALL_DIR to your PATH."
    }
}

function Ensure-Path {
    $line = '$env:PATH = "$HOME\.local\bin;$env:PATH"'
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not $profilePath) { $profilePath = "$HOME\Documents\PowerShell\Profile.ps1" }

    $profileDir = Split-Path $profilePath -Parent
    $null = New-Item -ItemType Directory -Force -Path $profileDir

    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Force -Path $profilePath | Out-Null
    }

    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch [regex]::Escape('$env:PATH = "$HOME\.local\bin;$env:PATH"')) {
        @"

# Local user scripts
`$env:PATH = "`$HOME\.local\bin;`$env:PATH"
"@ | Add-Content $profilePath
        Write-Ok "Added ~\.local\bin to PATH in $profilePath"
    }

    $env:PATH = "$INSTALL_DIR;$env:PATH"
}

# ─── Main logic ──────────────────────────────────────────────────────────────
if (-not $SkipInstall) {
    if ($ForceInstall -or -not (Get-Command oc-go-cc -ErrorAction SilentlyContinue)) {
        Install-OcGoCcFromSource
    }
    else {
        Write-Ok "oc-go-cc already installed: $(Get-Command oc-go-cc)"
        Write-Warn "Existing oc-go-cc may not be the freshly built fork binary. Re-run with -ForceInstall to rebuild from $OC_GO_CC_REPO_URL."
    }
}

Ensure-Path

# ─── API Key ─────────────────────────────────────────────────────────────────
if (-not $KEY) {
    $secureKey = Read-Host "Paste your OpenCode Go API key" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
if (-not $KEY) { Write-Fail "OpenCode Go API key is empty" }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (Test-Path "$OC_CONFIG_DIR\config.json") {
    Copy-Item "$OC_CONFIG_DIR\config.json" "$OC_CONFIG_DIR\config.json.bak.$timestamp"
    Write-Ok "Backed up oc-go-cc config."
}

if (Test-Path "$CLAUDE_DIR\settings.json") {
    Copy-Item "$CLAUDE_DIR\settings.json" "$CLAUDE_DIR\settings.json.bak.$timestamp"
    Write-Ok "Backed up Claude settings."
}

# ─── Store API key privately ─────────────────────────────────────────────────
@"
`$env:OC_GO_CC_API_KEY = '$KEY'
`$env:OC_GO_CC_LOG_LEVEL = 'debug'
"@ | Set-Content -Path "$OC_CONFIG_DIR\env.ps1" -NoNewline

$env:OC_GO_CC_API_KEY = $KEY
$env:DEEPSEEK_ONLY = if ($DeepseekOnly) { "1" } else { "0" }

Write-Info "Generating oc-go-cc and Claude configs..."

# ─── Python script to generate configs ───────────────────────────────────────
# We pass variables through environment so the embedded Python can access them.
# PowerShell mangles double quotes in native command args, so write to a temp file instead of -c.
$genPyPath = "$OC_CONFIG_DIR\generate_config.py"
@'
import json, os, re, shutil, urllib.request
from pathlib import Path

home = Path.home()
api_key = os.environ["OC_GO_CC_API_KEY"]
deepseek_only = os.environ.get("DEEPSEEK_ONLY") == "1"

KNOWN_OPENCODE_GO_MODELS = [
    "deepseek-v4-flash",
    "mimo-v2.5",
    "qwen3.7-plus",
    "kimi-k2.7-code",
    "deepseek-v4-pro",
    "minimax-m3",
    "qwen3.7-max",
    "glm-5.1",
    "mimo-v2.5-pro",
    "big-pickle",
]

def fetch_models():
    if deepseek_only:
        return ["deepseek-v4-flash"]

    known = KNOWN_OPENCODE_GO_MODELS.copy()
    url = "https://opencode.ai/zen/go/v1/models"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            payload = json.loads(r.read().decode("utf-8"))
    except Exception as e:
        print(f"WARNING: could not fetch live model list, using known registry: {e}")
        return known

    live_ids = set()

    def add(x):
        if isinstance(x, str) and x.strip():
            live_ids.add(x.strip())
        elif isinstance(x, dict):
            for key in ("id", "name", "model", "model_id"):
                if isinstance(x.get(key), str) and x[key].strip():
                    live_ids.add(x[key].strip())
                    return

    if isinstance(payload, dict):
        for key in ("data", "models", "items"):
            if isinstance(payload.get(key), list):
                for item in payload[key]:
                    add(item)
        add(payload)
    elif isinstance(payload, list):
        for item in payload:
            add(item)

    merged = known.copy()
    for m in sorted(live_ids - set(known)):
        merged.append(m)

    if not merged:
        print("WARNING: no models resolved, using known registry")
        return known

    return merged

def slug(model_id: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", model_id).strip("-").lower()
    return f"claude-ocgo-{s}"

def reasoning_like(model_id: str) -> bool:
    lo = model_id.lower()
    return any(x in lo for x in ["deepseek", "glm", "qwen"])

def caps_for(model_id: str):
    if reasoning_like(model_id):
        return "effort,xhigh_effort,max_effort,thinking,adaptive_thinking,interleaved_thinking,tool_use"
    return "tool_use"

def model_cfg(model_id: str, temperature=0.7, max_tokens=32768):
    cfg = {
        "provider": "opencode-go",
        "model_id": model_id,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    if reasoning_like(model_id):
        cfg["reasoning_effort"] = "high"
        cfg["thinking"] = {"type": "enabled"}
    return cfg

model_ids = fetch_models()
fallback = model_ids[0]

SLOT_MODEL_MAP = {
    "fable": "minimax-m3",
    "opus": "deepseek-v4-pro",
    "sonnet": "kimi-k2.7-code",
    "haiku": "deepseek-v4-flash",
    "custom": "qwen3.7-plus",
}

SLOT_VISIBLE_NAME = {
    "fable": "MiniMax M3",
    "opus": "DeepSeek V4 Pro",
    "sonnet": "Kimi K2.7 Code",
    "haiku": "DeepSeek V4 Flash",
    "custom": "Qwen3.7 Plus",
}

if deepseek_only:
    default_model = "deepseek-v4-flash"
    fable_model = opus_model = sonnet_model = haiku_model = custom_model = "deepseek-v4-flash"
else:
    default_model = "deepseek-v4-flash"
    fable_model = SLOT_MODEL_MAP["fable"]
    opus_model = SLOT_MODEL_MAP["opus"]
    sonnet_model = SLOT_MODEL_MAP["sonnet"]
    haiku_model = SLOT_MODEL_MAP["haiku"]
    custom_model = SLOT_MODEL_MAP["custom"]

alias_by_model = {mid: slug(mid) for mid in model_ids}

model_overrides = {}
for mid in model_ids:
    model_overrides[mid] = model_cfg(mid)
for mid, alias in alias_by_model.items():
    model_overrides[alias] = model_cfg(mid)

BUILTIN_MODEL_MAP = {
    "claude-opus-4-8": "deepseek-v4-pro",
    "claude-opus-4-6": "deepseek-v4-pro",
    "claude-opus-4-5": "deepseek-v4-pro",
    "claude-sonnet-4-6": "kimi-k2.7-code",
    "claude-sonnet-4-5": "kimi-k2.7-code",
    "claude-haiku-4-5-20251001": "deepseek-v4-flash",
    "claude-fable-5": "minimax-m3",
}
for name, target_id in BUILTIN_MODEL_MAP.items():
    model_overrides[name] = model_cfg(target_id)

all_fallbacks = [model_cfg(mid) for mid in model_ids]

oc_config = {
    "api_key": "${OC_GO_CC_API_KEY}",
    "host": "127.0.0.1",
    "port": 3456,
    "hot_reload": False,
    "models": {
        "default": model_cfg("deepseek-v4-flash"),
        "fast": model_cfg("kimi-k2.7-code"),
        "background": model_cfg("qwen3.7-plus", temperature=0.5, max_tokens=16384),
        "think": model_cfg("deepseek-v4-pro"),
        "complex": model_cfg("deepseek-v4-pro"),
        "long_context": {
            **model_cfg("minimax-m3"),
            "context_threshold": 80000,
        },
    },
    "fallbacks": {
        "default": all_fallbacks,
        "fast": all_fallbacks,
        "background": [model_cfg(mid, temperature=0.5, max_tokens=16384) for mid in model_ids],
        "think": all_fallbacks,
        "complex": all_fallbacks,
        "long_context": all_fallbacks,
    },
    "model_overrides": model_overrides,
    "opencode_go": {
        "base_url": "https://opencode.ai/zen/go/v1/chat/completions",
        "anthropic_base_url": "https://opencode.ai/zen/go/v1/messages",
        "timeout_ms": 300000,
    },
    "logging": {
        "level": "info",
        "requests": True,
    },
}

oc_path = home / ".config" / "oc-go-cc" / "config.json"
oc_path.write_text(json.dumps(oc_config, indent=2) + "\n")

claude_path = home / ".claude" / "settings.json"
try:
    data = json.loads(claude_path.read_text()) if claude_path.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    data = {}

data.pop("model", None)
data.pop("availableModels", None)
data.pop("enforceAvailableModels", None)

permissions = data.setdefault("permissions", {})
permissions["allow"] = ["*"]
permissions["defaultMode"] = "bypassPermissions"
data.pop("defaultMode", None)
data["skipDangerousModePermissionPrompt"] = True

if shutil.which("rtk"):
    hooks = data.setdefault("hooks", {})
    pre = hooks.setdefault("PreToolUse", [])
    exists = False
    for item in pre:
        if isinstance(item, dict) and item.get("matcher") == "Bash":
            for h in item.get("hooks", []):
                if isinstance(h, dict) and h.get("command") == "rtk hook claude":
                    exists = True
    if not exists:
        pre.append({
            "matcher": "Bash",
            "hooks": [
                {
                    "type": "command",
                    "command": "rtk hook claude",
                }
            ],
        })

env = data.setdefault("env", {})
env.pop("ANTHROPIC_API_KEY", None)
env.pop("CLAUDE_CODE_OAUTH_TOKEN", None)

env.update({
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:3456",
    "ANTHROPIC_AUTH_TOKEN": "unused",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
    "CLAUDE_CODE_ALWAYS_ENABLE_EFFORT": "1",
    "CLAUDE_CODE_EFFORT_LEVEL": "high",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
})

def set_slot(var_base, mid, visible_name):
    alias = alias_by_model.get(mid, slug(mid))
    env[f"{var_base}_MODEL"] = alias
    env[f"{var_base}_MODEL_NAME"] = f"{visible_name} \u00b7 {mid}"
    env[f"{var_base}_MODEL_DESCRIPTION"] = f"{mid} via OpenCode Go / oc-go-cc"
    env[f"{var_base}_MODEL_SUPPORTED_CAPABILITIES"] = caps_for(mid)

set_slot("ANTHROPIC_DEFAULT_FABLE", fable_model, SLOT_VISIBLE_NAME["fable"])
set_slot("ANTHROPIC_DEFAULT_OPUS", opus_model, SLOT_VISIBLE_NAME["opus"])
set_slot("ANTHROPIC_DEFAULT_SONNET", sonnet_model, SLOT_VISIBLE_NAME["sonnet"])
set_slot("ANTHROPIC_DEFAULT_HAIKU", haiku_model, SLOT_VISIBLE_NAME["haiku"])

custom_alias = alias_by_model.get(custom_model, slug(custom_model))
env["ANTHROPIC_CUSTOM_MODEL_OPTION"] = custom_alias
env["ANTHROPIC_CUSTOM_MODEL_OPTION_NAME"] = f"{SLOT_VISIBLE_NAME['custom']} \u00b7 {custom_model}"
env["ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION"] = f"{custom_model} via OpenCode Go / oc-go-cc"
env["ANTHROPIC_CUSTOM_MODEL_OPTION_SUPPORTED_CAPABILITIES"] = caps_for(custom_model)

claude_dir = home / ".claude"
output_styles_dir = claude_dir / "output-styles"
themes_dir = claude_dir / "themes"
agents_dir = claude_dir / "agents"
for d in (output_styles_dir, themes_dir, agents_dir):
    d.mkdir(parents=True, exist_ok=True)

data["theme"] = "custom:cyberpunk"
data["tui"] = "fullscreen"
data["terminalProgressBarEnabled"] = True
data["outputStyle"] = "Truth Gated Coder"
data["spinnerVerbs"] = {
    "mode": "append",
    "verbs": ["Forging", "Compiling", "Wiring", "Verifying", "Summoning", "Truth-gating"],
}
data["spinnerTipsOverride"] = {
    "excludeDefault": False,
    "tips": [
        "Truth Gate: verify before claiming done.",
        "Small patches beat giant rewrites.",
        "Wire the feature, then prove it.",
        "Changed files + commands run + pass/fail evidence, always.",
    ],
}
data["statusLine"] = {
    "type": "command",
    "command": str(claude_dir / "statusline.sh"),
    "padding": 1,
    "refreshInterval": 5,
}

truth_output_style = '''---
name: Truth Gated Coder
description: Multi-agent coding workflow with verification evidence
keep-coding-instructions: true
---

You are a truth-gated coding agent.

For any non-trivial code change, use this default workflow:

1. architect-reviewer maps affected files, integration points, wiring points, risks, and acceptance criteria.
2. implementation writes the smallest working patch.
3. typescript-pro handles TypeScript-specific implementation and type-level correctness when relevant.
4. react-specialist handles React/frontend/component/state/UI work when relevant.
5. test-automator adds or updates tests for changed behavior.
6. debugger runs the relevant check/build/test commands and fixes failures.
7. code-reviewer verifies:
   - no fake completion
   - no dead code
   - no unwired feature
   - no missing imports
   - no untested critical path
   - no contradicted final claim

Final response for coding tasks must include:
- changed files
- commands run
- pass/fail evidence
- known limitations
- anything not completed

Never claim completion unless the relevant checks were actually run.
If checks could not be run, explicitly say why.
Prefer small, verifiable patches over large speculative rewrites.
'''
(output_styles_dir / "truth-gated-coder.md").write_text(truth_output_style)

personal_claude_block = '''<!-- >>> claude-opencode-go-personalization >>> -->
# Personal Claude Code Defaults

I prefer production-grade, truth-gated coding.

For substantial coding tasks:
- Use architect-reviewer before implementation.
- Use typescript-pro for TypeScript work.
- Use react-specialist for React/frontend work.
- Use test-automator for tests.
- Use debugger for failing commands.
- Use code-reviewer before final response.

Always prefer:
- small patches
- real wiring over placeholder code
- tests or verification commands
- explicit pass/fail evidence
- honest limitations

Avoid:
- fake completion
- dead code
- unused files
- unwired UI
- claiming tests passed without running them
- huge rewrites unless explicitly necessary

Final answer for coding tasks must include:
- changed files
- commands run
- pass/fail evidence
- known limitations
<!-- <<< claude-opencode-go-personalization <<< -->
'''

def upsert_managed_block(path: Path, block: str, start: str, end: str):
    existing = path.read_text(errors="replace") if path.exists() else ""
    if start in existing and end in existing:
        before = existing.split(start, 1)[0].rstrip()
        after = existing.split(end, 1)[1].lstrip()
        new_text = (before + "\n\n" if before else "") + block.rstrip() + ("\n\n" + after if after else "\n")
    else:
        new_text = existing.rstrip() + ("\n\n" if existing.strip() else "") + block
    path.write_text(new_text)

upsert_managed_block(
    claude_dir / "CLAUDE.md",
    personal_claude_block,
    "<!-- >>> claude-opencode-go-personalization >>> -->",
    "<!-- <<< claude-opencode-go-personalization <<< -->",
)

cyberpunk_theme = {
    "name": "Cyberpunk",
    "base": "dark",
    "overrides": {
        "claude": "#bd93f9",
        "success": "#50fa7b",
        "error": "#ff5555",
        "warning": "#ffb86c",
        "info": "#8be9fd",
    },
}
(themes_dir / "cyberpunk.json").write_text(json.dumps(cyberpunk_theme, indent=2) + "\n")

statusline = r'''#!/usr/bin/env bash
set -euo pipefail
payload="$(cat || true)"
python3 -c '
import json, os, subprocess, sys
payload = sys.stdin.read()
try:
    data = json.loads(payload) if payload.strip() else {}
except Exception:
    data = {}
model = data.get("model", {})
if isinstance(model, dict):
    model_name = model.get("display_name") or model.get("name") or "Claude"
else:
    model_name = "Claude"
workspace = data.get("workspace", {}) if isinstance(data.get("workspace", {}), dict) else {}
dir_path = workspace.get("current_dir") or os.getcwd()
folder = os.path.basename(dir_path.rstrip(os.sep)) or dir_path
ctx = data.get("context_window", {}) if isinstance(data.get("context_window", {}), dict) else {}
pct = ctx.get("used_percentage", 0)
try:
    pct = int(float(pct))
except Exception:
    pct = 0
branch = ""
try:
    branch = subprocess.check_output(["git", "-C", dir_path, "branch", "--show-current"], stderr=subprocess.DEVNULL, text=True).strip()
except Exception:
    pass
PURPLE="\033[38;5;141m"; CYAN="\033[38;5;51m"; GREEN="\033[38;5;82m"; YELLOW="\033[38;5;226m"; RESET="\033[0m"
parts = [f"{PURPLE}\u25c6 {model_name}{RESET}", f"{CYAN}{folder}{RESET}"]
if branch:
    parts.append(f"{GREEN}\ue0a0 {branch}{RESET}")
parts.append(f"{YELLOW}{pct}% ctx{RESET}")
print("  ".join(parts))
' <<< "$payload"
'''
statusline_path = claude_dir / "statusline.sh"
statusline_path.write_text(statusline)
statusline_path.chmod(0o755)

agents = {
    "architect-reviewer.md": '''---
name: architect-reviewer
description: Use before non-trivial code changes to map affected files, integration points, risks, and acceptance criteria.
---

You are an architecture reviewer for agentic coding tasks.

Before implementation, inspect the relevant repo context and produce a concise implementation map:
- affected files
- integration/wiring points
- data flow and API boundaries
- risks and likely failure modes
- smallest safe patch plan
- concrete acceptance criteria

Do not implement code unless explicitly asked. Prefer actionable, verifiable guidance over broad architecture prose.
''',
    "typescript-pro.md": '''---
name: typescript-pro
description: Use for TypeScript, Node, Vite, React type safety, imports, interfaces, and build correctness.
---

You are a TypeScript specialist.

Focus on:
- type-level correctness
- strict imports/exports
- safe interfaces and schema boundaries
- avoiding any/unknown abuse unless justified
- preserving existing project conventions
- making npm run typecheck/build pass

Prefer minimal changes. Always mention typecheck/build commands that should verify the work.
''',
    "react-specialist.md": '''---
name: react-specialist
description: Use for React/frontend/component/state/UI work, especially wiring UI to real behavior.
---

You are a React/frontend specialist.

Focus on:
- real wired UI, not placeholders
- state/data flow correctness
- accessibility
- responsive layout
- loading/empty/error states
- component boundaries
- avoiding generic AI-looking UI

Prefer production-feeling implementation with the smallest safe patch.
''',
    "test-automator.md": '''---
name: test-automator
description: Use after implementation to add or update tests for changed behavior.
---

You are a test automation specialist.

Focus on:
- tests that verify the changed behavior, not snapshots of implementation details
- regression tests for previously broken wiring
- unit tests when logic changed
- integration/e2e tests when flows changed
- realistic failure cases

Prefer tests that would fail before the patch and pass after it.
''',
    "debugger.md": '''---
name: debugger
description: Use when checks fail, runtime behavior is wrong, or logs/errors need investigation.
---

You are a debugging specialist.

Focus on:
- reproducing the failure
- reading exact errors and logs
- finding root cause before patching
- applying the smallest fix
- rerunning the relevant command

Never hide failed commands. Report what failed, what changed, and what now passes.
''',
    "code-reviewer.md": '''---
name: code-reviewer
description: Use before final response to verify no fake completion, dead code, unwired feature, missing imports, or contradicted final claim.
---

You are a strict code reviewer and truth gate.

Review for:
- fake completion
- dead code
- unused files
- unwired UI or API paths
- missing imports/exports
- missing tests on critical paths
- contradicted final claims
- commands claimed as passed but not run

Final review must be evidence-based. If something is not verified, say so explicitly.
''',
}
for filename, content in agents.items():
    (agents_dir / filename).write_text(content)

personalization_summary = claude_dir / "personalization-summary.txt"
personalization_summary.write_text('''Claude Code personalization installed by setup-claude-opencode-go.ps1

Files:
  ~/.claude/settings.json
  ~/.claude/CLAUDE.md
  ~/.claude/output-styles/truth-gated-coder.md
  ~/.claude/themes/cyberpunk.json
  ~/.claude/statusline.sh
  ~/.claude/agents/architect-reviewer.md
  ~/.claude/agents/typescript-pro.md
  ~/.claude/agents/react-specialist.md
  ~/.claude/agents/test-automator.md
  ~/.claude/agents/debugger.md
  ~/.claude/agents/code-reviewer.md

Launchers:
  claude-ocgo.ps1         OpenCode Go gateway + bypassPermissions
  claude-truth.ps1        Normal Claude Code + bypassPermissions + personalization settings
  ocgo-routing-doctor.ps1 Print alias -> exact model_id routing table

Recommended first Claude Code command:
  /config

Verify selected output style/theme if Claude Code version requires manual activation:
  /output-style
  /theme
  /statusline
''')

claude_path.write_text(json.dumps(data, indent=2) + "\n")

model_list_path = home / ".claude" / "opencode-go-models.txt"
lines = []
lines.append("OpenCode Go models configured for Claude Code via oc-go-cc")
lines.append("")
lines.append("=" * 60)
lines.append("PICKER SLOTS (Fable / Opus / Sonnet / Haiku / Custom)")
lines.append("=" * 60)
for label, mid in [("Fable", fable_model), ("Opus", opus_model), ("Sonnet", sonnet_model), ("Haiku", haiku_model), ("Custom", custom_model)]:
    alias = alias_by_model.get(mid, slug(mid))
    lines.append(f"  {label:8s}  ->  /model {alias}  ->  {mid}")
lines.append("")
lines.append("=" * 60)
lines.append("ALL /model ALIASES (use inside Claude Code)")
lines.append("=" * 60)
for mid in model_ids:
    lines.append(f"  /model {alias_by_model[mid]:40s}  # {mid}")
lines.append("")
lines.append("=" * 60)
lines.append("CLAUDE BUILT-IN NAME MAPPING")
lines.append("=" * 60)
for name, target_id in BUILTIN_MODEL_MAP.items():
    alias = alias_by_model.get(target_id, slug(target_id))
    lines.append(f"  {name:40s}  ->  /model {alias}  ->  {target_id}")
lines.append("")
model_list_path.write_text("\n".join(lines) + "\n")

print("")
print("WROTE:")
print(f"  {oc_path}")
print(f"  {claude_path}")
print(f"  {model_list_path}")
print("")
print("DISCOVERED/CONFIGURED MODELS:")
for mid in model_ids:
    print(f"  - {mid}  =>  {alias_by_model[mid]}")
print("")
print("PICKER SLOT MAP:")
print(f"  fable  -> {fable_model}")
print(f"  opus   -> {opus_model}")
print(f"  sonnet -> {sonnet_model}")
print(f"  haiku  -> {haiku_model}")
print(f"  custom -> {custom_model}")
'@ | Set-Content -Path $genPyPath -Encoding ASCII

& $PYTHON_EXE $genPyPath
if ($LASTEXITCODE -ne 0) {
    Remove-Item $genPyPath -Force -ErrorAction SilentlyContinue
    Write-Fail "Python config generation failed."
}
Remove-Item $genPyPath -Force -ErrorAction SilentlyContinue

Write-Info "Creating launcher scripts..."

# ─── Launcher: start-oc-go-cc.ps1 ────────────────────────────────────────────
@"
# start-oc-go-cc.ps1
# Starts the oc-go-cc proxy server
`$env:OC_GO_CC_API_KEY = '$KEY'
`$env:OC_GO_CC_LOG_LEVEL = 'debug'
& "$INSTALL_DIR\oc-go-cc.exe" serve
"@ | Set-Content -Path "$INSTALL_DIR\start-oc-go-cc.ps1" -NoNewline

# ─── Launcher: claude-ocgo.ps1 ───────────────────────────────────────────────
@'
# claude-ocgo.ps1
# Launches Claude Code routed through oc-go-cc (OpenCode Go gateway)
$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:3456"
$env:ANTHROPIC_AUTH_TOKEN = "unused"
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
$env:CLAUDE_CODE_ALWAYS_ENABLE_EFFORT = "1"
$env:CLAUDE_CODE_EFFORT_LEVEL = "high"
$env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"

# 5-slot model env vars (deterministic — do not rely on settings.json alone)
$env:ANTHROPIC_DEFAULT_FABLE_MODEL = "claude-ocgo-minimax-m3"
$env:ANTHROPIC_DEFAULT_FABLE_MODEL_NAME = "MiniMax M3 · minimax-m3"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-ocgo-deepseek-v4-pro"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL_NAME = "DeepSeek V4 Pro · deepseek-v4-pro"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-ocgo-kimi-k2-7-code"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL_NAME = "Kimi K2.7 Code · kimi-k2.7-code"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-ocgo-deepseek-v4-flash"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME = "DeepSeek V4 Flash · deepseek-v4-flash"
$env:ANTHROPIC_CUSTOM_MODEL_OPTION = "claude-ocgo-qwen3-7-plus"
$env:ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = "Qwen3.7 Plus · qwen3.7-plus"

claude --permission-mode bypassPermissions @args
'@ | Set-Content -Path "$INSTALL_DIR\claude-ocgo.ps1" -NoNewline

# ─── Launcher: claude-truth.ps1 ──────────────────────────────────────────────
@'
# claude-truth.ps1
# Launches Claude Code with truth-gated personalization and bypassPermissions
claude --permission-mode bypassPermissions @args
'@ | Set-Content -Path "$INSTALL_DIR\claude-truth.ps1" -NoNewline

# ─── Write routing-doctor Python script (used by launcher) ────────────────
$routingDoctorPy = @'
import json, os, sys, shutil, subprocess
from pathlib import Path

cfg_path = Path(os.environ["OC_CONFIG"])
settings_path = Path(os.environ["CLAUDE_SETTINGS"])
cfg = json.loads(cfg_path.read_text())
settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
mo = cfg.get("model_overrides", {})

REQUIRED_ALIASES = {
    "claude-ocgo-minimax-m3": "minimax-m3",
    "claude-ocgo-deepseek-v4-pro": "deepseek-v4-pro",
    "claude-ocgo-kimi-k2-7-code": "kimi-k2.7-code",
    "claude-ocgo-qwen3-7-plus": "qwen3.7-plus",
    "claude-ocgo-deepseek-v4-flash": "deepseek-v4-flash",
}

REQUIRED_MODELS_SLOTS = {
    "default": "deepseek-v4-flash",
    "fast": "kimi-k2.7-code",
    "background": "qwen3.7-plus",
    "think": "deepseek-v4-pro",
    "complex": "deepseek-v4-pro",
    "long_context": "minimax-m3",
}

REQUIRED_SETTINGS_ENV = {
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "claude-ocgo-minimax-m3",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-ocgo-deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-ocgo-kimi-k2-7-code",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-ocgo-deepseek-v4-flash",
    "ANTHROPIC_CUSTOM_MODEL_OPTION": "claude-ocgo-qwen3-7-plus",
}

print("=" * 60)
print("oc-go-cc ROUTING DOCTOR")
print("=" * 60)
print("")

binary = shutil.which("oc-go-cc") or "<not found in PATH>"
print(f"--- Installed oc-go-cc binary ---")
print(f"  {binary}")
print("")

failures = 0

print("--- Active Claude settings slot env values ---")
env = settings.get("env", {})
for key, want in REQUIRED_SETTINGS_ENV.items():
    got = env.get(key, "<missing>")
    ok = got == want
    print(f"  {key:40s} = {got}   {'OK' if ok else 'FAIL (expected ' + want + ')'}")
    if not ok:
        failures += 1
print("")

print("--- model_overrides alias -> backend model_id ---")
for alias, want in REQUIRED_ALIASES.items():
    got = mo.get(alias, {}).get("model_id", "<missing>")
    ok = got == want
    print(f"  {alias:40s} -> {got}   {'OK' if ok else 'FAIL (expected ' + want + ')'}")
    if not ok:
        failures += 1
print("")

print("--- models.* slot mapping ---")
slots = cfg.get("models", {})
for slot, want in REQUIRED_MODELS_SLOTS.items():
    got = slots.get(slot, {}).get("model_id", "<missing>")
    ok = got == want
    print(f"  {slot:14s} -> {got}   {'OK' if ok else 'FAIL (expected ' + want + ')'}")
    if not ok:
        failures += 1
print("")

print(f"Total model_overrides: {len(mo)}")
print(f"Failures: {failures}")
if failures:
    print("ROUTING_DOCTOR_FAIL")
    sys.exit(1)
print("ROUTING_DOCTOR_PASS")
'@
$routingDoctorPy | Set-Content -Path "$OC_CONFIG_DIR\routing-doctor.py" -NoNewline

# ─── Launcher: ocgo-routing-doctor.ps1 ───────────────────────────────────────
$routingDoctorLauncher = @'
# ocgo-routing-doctor.ps1
# Verifies oc-go-cc routing configuration

$OC_CONFIG = "$HOME\.config\oc-go-cc\config.json"
$CLAUDE_SETTINGS = "$HOME\.claude\settings.json"

if (-not (Test-Path $OC_CONFIG)) {
    Write-Host "ERROR: $OC_CONFIG not found. Run the setup script first." -ForegroundColor Red
    exit 1
}

$env:OC_CONFIG = $OC_CONFIG
$env:CLAUDE_SETTINGS = $CLAUDE_SETTINGS
python "$HOME\.config\oc-go-cc\routing-doctor.py"
'@
$routingDoctorLauncher | Set-Content -Path "$INSTALL_DIR\ocgo-routing-doctor.ps1" -NoNewline

Write-Info "Validating oc-go-cc config..."
$ocGoCc = Get-Command oc-go-cc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($ocGoCc) {
    $env:OC_GO_CC_API_KEY = $KEY
    $env:OC_GO_CC_LOG_LEVEL = "debug"
    & $ocGoCc validate
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "oc-go-cc validate failed. Check $OC_CONFIG_DIR\config.json"
    }
}
else {
    Write-Warn "oc-go-cc is not in PATH yet. Run your profile script or add $INSTALL_DIR to PATH."
}

Write-Ok "Done."
@"
Next commands:

  . "$OC_CONFIG_DIR\env.ps1"
  start-oc-go-cc

In another terminal:

  claude-ocgo

Or, for normal Claude Code with your global personalization only:

  claude-truth

Inside Claude Code:

  /clear opencode-go-test
  /model

Personalization summary:

  Get-Content ~\.claude\personalization-summary.txt

Manual model aliases:

  Get-Content ~\.claude\opencode-go-models.txt

Verify routing table:

  ocgo-routing-doctor

Cache reset (run once after first install, or if routing looks wrong):

  taskkill /F /IM oc-go-cc* 2>nul
  taskkill /F /IM claude* 2>nul
  Remove-Item ~\.claude\cache\gateway-models.json -ErrorAction SilentlyContinue
  . "$OC_CONFIG_DIR\env.ps1"
  start-oc-go-cc
"@ | Write-Host
