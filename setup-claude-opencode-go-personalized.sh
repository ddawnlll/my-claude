#!/usr/bin/env bash
# setup-claude-opencode-go.sh
#
# One-shot installer/configurator for:
#   Claude Code / Claude Desktop -> oc-go-cc -> OpenCode Go
#
# What it does:
#   1) Clones https://github.com/ddawnlll/oc-go-cc into $HOME/.local/src/oc-go-cc
#      (or updates the existing checkout) and runs `make build` to produce the binary
#   2) Installs the resulting binary to $INSTALL_DIR/oc-go-cc
#   3) Saves your OpenCode Go API key privately at ~/.config/oc-go-cc/env
#   4) Fetches the live OpenCode Go model list
#   5) Writes ~/.config/oc-go-cc/config.json
#   6) Writes/repairs ~/.claude/settings.json
#   7) Installs Mehmet's global Claude Code personalization layer:
#        - permissive bypassPermissions mode in the correct settings location
#        - truth-gated coder output style
#        - global CLAUDE.md coding rules
#        - global subagents: architect-reviewer, typescript-pro, react-specialist,
#          test-automator, debugger, code-reviewer
#        - cyberpunk theme + fullscreen TUI + animated spinner verbs/tips
#        - custom statusline without jq dependency
#   8) Creates launcher commands:
#        start-oc-go-cc
#        claude-ocgo
#        claude-truth
#        ocgo-routing-doctor
#        open-claude-desktop-ocgo   macOS only
#
# Usage:
#   chmod +x setup-claude-opencode-go.sh
#   ./setup-claude-opencode-go.sh --key "sk-opencode-your-key"
#
# Or:
#   export OC_GO_CC_API_KEY="sk-opencode-your-key"
#   ./setup-claude-opencode-go.sh

set -Eeuo pipefail

OC_GO_CC_REPO_URL="${OC_GO_CC_REPO_URL:-https://github.com/ddawnlll/oc-go-cc.git}"
OC_GO_CC_REPO_BRANCH="${OC_GO_CC_REPO_BRANCH:-main}"
OC_GO_CC_SOURCE_DIR="${OC_GO_CC_SOURCE_DIR:-$HOME/.local/src/oc-go-cc}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
OC_CONFIG_DIR="$HOME/.config/oc-go-cc"
CLAUDE_DIR="$HOME/.claude"

KEY="${OC_GO_CC_API_KEY:-}"
FORCE_INSTALL="0"
DEEPSEEK_ONLY="0"
SKIP_INSTALL="0"
NO_UPDATE_SOURCE="0"
FULL_INTEL="${FULL_INTEL:-1}"

fail() { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }
warn() { printf "\033[1;33mWARN:\033[0m %s\n" "$*" >&2; }
info() { printf "\033[1;34m%s\033[0m\n" "$*"; }
ok() { printf "\033[1;32m%s\033[0m\n" "$*"; }

usage() {
  cat <<'EOF'
Usage:
  ./setup-claude-opencode-go-personalized.sh --key "sk-opencode-your-key"

Options:
  --key VALUE           OpenCode Go API key. You can also set OC_GO_CC_API_KEY.
  --force-install       Rebuild and reinstall oc-go-cc from Mehmet's fork.
  --skip-install        Do not clone/build/install; only write configs.
  --deepseek-only       Configure only deepseek-v4-flash with high thinking.
  --source-dir PATH     Override oc-go-cc source checkout path.
                        (default: $HOME/.local/src/oc-go-cc, env: OC_GO_CC_SOURCE_DIR)
  --branch NAME         Override git branch for the fork. (default: main, env: OC_GO_CC_REPO_BRANCH)
  --no-update-source    Do not git fetch/reset existing source checkout; just build current.
  --full-intel          Install full intelligence pack (plugins, MCP, Tavily, commands).
                        (default: enabled)
  --skip-intel          Skip full intelligence pack installation.
  -h, --help            Show help.

Source repo:
  https://github.com/ddawnlll/oc-go-cc
  Cloned and built with 'make build' from the fork — no upstream release binary.

Troubleshooting a broken build:
  cd ~/.local/src/oc-go-cc && make build

After install:
  start-oc-go-cc

In another terminal:
  claude-ocgo

Inside Claude Code:
  /clear opencode-go-test
  /model

Model aliases:
  cat ~/.claude/opencode-go-models.txt

Verify routing:
  ocgo-routing-doctor
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)
      KEY="${2:-}"
      shift 2
      ;;
    --force-install)
      FORCE_INSTALL="1"
      shift
      ;;
    --skip-install)
      SKIP_INSTALL="1"
      shift
      ;;
    --deepseek-only)
      DEEPSEEK_ONLY="1"
      shift
      ;;
    --source-dir)
      OC_GO_CC_SOURCE_DIR="${2:-}"
      [[ -n "$OC_GO_CC_SOURCE_DIR" ]] || fail "--source-dir requires a path"
      shift 2
      ;;
    --branch)
      OC_GO_CC_REPO_BRANCH="${2:-}"
      [[ -n "$OC_GO_CC_REPO_BRANCH" ]] || fail "--branch requires a name"
      shift 2
      ;;
    --no-update-source)
      NO_UPDATE_SOURCE="1"
      shift
      ;;
    --full-intel)
      FULL_INTEL="1"
      shift
      ;;
    --skip-intel|--no-intel)
      FULL_INTEL="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v curl >/dev/null 2>&1 || fail "curl is required"

# Source build dependencies. Only checked when not --skip-install.
require_source_build_tools() {
  command -v git >/dev/null 2>&1  || fail "git is required to clone $OC_GO_CC_REPO_URL. Install git."
  command -v make >/dev/null 2>&1 || fail "make is required to build oc-go-cc from source. Install make / build-essential."
  command -v go >/dev/null 2>&1   || fail "go is required to build oc-go-cc from source. Install Go (>= 1.22)."
}

mkdir -p "$INSTALL_DIR" "$OC_CONFIG_DIR" "$CLAUDE_DIR" "$HOME/.claude/commands" "$HOME/.claude/commands/community"

install_oc_go_cc_from_source() {
  local target="$INSTALL_DIR/oc-go-cc"
  local parent

  require_source_build_tools

  parent="$(dirname "$OC_GO_CC_SOURCE_DIR")"
  mkdir -p "$parent" "$INSTALL_DIR"

  if [[ ! -d "$OC_GO_CC_SOURCE_DIR/.git" ]]; then
    info "Cloning $OC_GO_CC_REPO_URL (branch $OC_GO_CC_REPO_BRANCH) into $OC_GO_CC_SOURCE_DIR ..."
    rm -rf "$OC_GO_CC_SOURCE_DIR"
    git clone --branch "$OC_GO_CC_REPO_BRANCH" "$OC_GO_CC_REPO_URL" "$OC_GO_CC_SOURCE_DIR"
  elif [[ "$NO_UPDATE_SOURCE" == "1" ]]; then
    info "Using existing source checkout at $OC_GO_CC_SOURCE_DIR (--no-update-source)."
  else
    info "Updating existing source checkout at $OC_GO_CC_SOURCE_DIR ..."
    if ! git -C "$OC_GO_CC_SOURCE_DIR" remote -v | grep -q -F "$OC_GO_CC_REPO_URL"; then
      warn "Source dir exists but its origin is not $OC_GO_CC_REPO_URL."
      warn "Re-cloning to ensure binary comes from Mehmet's fork."
      rm -rf "$OC_GO_CC_SOURCE_DIR"
      git clone --branch "$OC_GO_CC_REPO_BRANCH" "$OC_GO_CC_REPO_URL" "$OC_GO_CC_SOURCE_DIR"
    else
      git -C "$OC_GO_CC_SOURCE_DIR" fetch origin "$OC_GO_CC_REPO_BRANCH"
      git -C "$OC_GO_CC_SOURCE_DIR" reset --hard "origin/$OC_GO_CC_REPO_BRANCH"
      git -C "$OC_GO_CC_SOURCE_DIR" clean -fdx
    fi
  fi

  info "Running 'make build' in $OC_GO_CC_SOURCE_DIR ..."
  ( cd "$OC_GO_CC_SOURCE_DIR" && make build )

  local built=""
  for cand in \
      "$OC_GO_CC_SOURCE_DIR/oc-go-cc" \
      "$OC_GO_CC_SOURCE_DIR/bin/oc-go-cc" \
      "$OC_GO_CC_SOURCE_DIR/build/oc-go-cc" \
      "$OC_GO_CC_SOURCE_DIR/dist/oc-go-cc" \
      "$OC_GO_CC_SOURCE_DIR/cmd/oc-go-cc/oc-go-cc" ; do
    if [[ -x "$cand" ]]; then
      built="$cand"
      break
    fi
  done

  if [[ -z "$built" ]]; then
    # Fallback: search for any executable named oc-go-cc outside .git.
    while IFS= read -r cand; do
      [[ -n "$cand" ]] && built="$cand" && break
    done < <(find "$OC_GO_CC_SOURCE_DIR" -type f -perm -111 -name 'oc-go-cc' -not -path '*/.git/*' 2>/dev/null | awk '{ print length($0) "\t" $0 }' | sort -n | cut -f2-)
  fi

  if [[ -z "$built" ]]; then
    echo "ERROR: make build completed but no oc-go-cc executable was found." >&2
    echo "Diagnostics:" >&2
    echo "  ls -la $OC_GO_CC_SOURCE_DIR" >&2
    ls -la "$OC_GO_CC_SOURCE_DIR" >&2 || true
    echo "  find executables (maxdepth 4):" >&2
    find "$OC_GO_CC_SOURCE_DIR" -maxdepth 4 -type f -perm -111 -not -path '*/.git/*' >&2 || true
    exit 1
  fi

  ok "Built binary: $built"
  cp -f "$built" "$target"
  chmod +x "$target"
  ok "Installed oc-go-cc to $target"

  local commit=""
  commit="$(git -C "$OC_GO_CC_SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  ok "Source commit: $commit"

  export PATH="$INSTALL_DIR:$PATH"

  if command -v oc-go-cc >/dev/null 2>&1; then
    oc-go-cc --version 2>/dev/null || warn "oc-go-cc is installed but --version did not return a value; continuing."
    ok "Active oc-go-cc: $(command -v oc-go-cc)"
  else
    warn "oc-go-cc installed but not found in current PATH. Use: export PATH=\"$INSTALL_DIR:\$PATH\""
  fi
}

ensure_path() {
  local line='export PATH="$HOME/.local/bin:$PATH"'
  local shell_name profile

  shell_name="${SHELL:-}"
  if [[ "$shell_name" == *zsh ]]; then
    profile="$HOME/.zshrc"
  elif [[ "$shell_name" == *bash ]]; then
    profile="$HOME/.bashrc"
  else
    profile="$HOME/.profile"
  fi

  touch "$profile"
  if ! grep -Fq "$line" "$profile"; then
    {
      echo ""
      echo "# Local user scripts"
      echo "$line"
    } >> "$profile"
    ok "Added ~/.local/bin to PATH in $profile"
  fi

  export PATH="$INSTALL_DIR:$PATH"
}

if [[ "$SKIP_INSTALL" != "1" ]]; then
  if [[ "$FORCE_INSTALL" == "1" ]] || ! command -v oc-go-cc >/dev/null 2>&1; then
    install_oc_go_cc_from_source
  else
    ok "oc-go-cc already installed: $(command -v oc-go-cc)"
    warn "Existing oc-go-cc may not be the freshly built fork binary. Re-run with --force-install to rebuild from $OC_GO_CC_REPO_URL."
    oc-go-cc --version 2>/dev/null || true
  fi
fi

ensure_path

if [[ -z "$KEY" ]]; then
  read -r -s -p "Paste your OpenCode Go API key: " KEY
  echo
fi
[[ -n "$KEY" ]] || fail "OpenCode Go API key is empty"

timestamp="$(date +%Y%m%d-%H%M%S)"

if [[ -f "$OC_CONFIG_DIR/config.json" ]]; then
  cp "$OC_CONFIG_DIR/config.json" "$OC_CONFIG_DIR/config.json.bak.$timestamp"
  ok "Backed up oc-go-cc config."
fi

if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$timestamp"
  ok "Backed up Claude settings."
fi

# Store API key privately for launchers.
umask 077
{
  printf 'export OC_GO_CC_API_KEY=%q\n' "$KEY"
  printf 'export OC_GO_CC_LOG_LEVEL=debug\n'
} > "$OC_CONFIG_DIR/env"
chmod 600 "$OC_CONFIG_DIR/env"
export OC_GO_CC_API_KEY="$KEY"
export DEEPSEEK_ONLY="$DEEPSEEK_ONLY"

info "Generating oc-go-cc and Claude configs..."

python3 <<'PY'
import json
import os
import re
import shutil
import urllib.request
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

    # Additive-only merge: known models in preferred order, then unknown live models appended.
    # Live fetch is additive only — it must never prune known models from the generated config.
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

def pick(preferred, available, fallback):
    for p in preferred:
        if p in available:
            return p
    return fallback

model_ids = fetch_models()
fallback = model_ids[0]

# Slot mapping is explicit and deterministic — does NOT depend on live model availability.
# Each Claude Code picker slot is bound to one exact backend model_id.
SLOT_MODEL_MAP = {
    "fable": "minimax-m3",
    "opus": "deepseek-v4-pro",
    "sonnet": "kimi-k2.7-code",
    "haiku": "deepseek-v4-flash",
    "custom": "qwen3.7-plus",
}

# Visible display names for the Claude Code picker.
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

# Exact OpenCode Go IDs — every model gets an override.
for mid in model_ids:
    model_overrides[mid] = model_cfg(mid)

# claude-ocgo-* aliases — each routes to its exact model_id.
for mid, alias in alias_by_model.items():
    model_overrides[alias] = model_cfg(mid)

# Claude built-in names — intentional per-model routing, NOT collapsing to default.
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

# Claude settings merge/repair.
claude_path = home / ".claude" / "settings.json"
try:
    data = json.loads(claude_path.read_text()) if claude_path.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    data = {}

# Remove broken forced model and allowlist constraints.
data.pop("model", None)
data.pop("availableModels", None)
data.pop("enforceAvailableModels", None)

# Keep useful user settings but make default mode permissive.
# IMPORTANT: defaultMode belongs under permissions.defaultMode, not top-level.
permissions = data.setdefault("permissions", {})
permissions["allow"] = ["*"]
permissions["defaultMode"] = "bypassPermissions"
data.pop("defaultMode", None)
data["skipDangerousModePermissionPrompt"] = True

# Preserve existing hooks/plugins. Add rtk hook only when rtk exists and not already present.
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

# Remove auth conflicts.
env.pop("ANTHROPIC_API_KEY", None)
env.pop("CLAUDE_CODE_OAUTH_TOKEN", None)

env.update({
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:3456",
    "ANTHROPIC_AUTH_TOKEN": "unused",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
    "CLAUDE_CODE_ALWAYS_ENABLE_EFFORT": "1",
    # Reduces beta endpoint incompatibility problems with some local proxies.
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
})

def set_slot(var_base, mid, visible_name):
    alias = alias_by_model.get(mid, slug(mid))
    env[f"{var_base}_MODEL"] = alias
    env[f"{var_base}_MODEL_NAME"] = f"{visible_name} · {mid}"
    env[f"{var_base}_MODEL_DESCRIPTION"] = f"{mid} via OpenCode Go / oc-go-cc"
    env[f"{var_base}_MODEL_SUPPORTED_CAPABILITIES"] = caps_for(mid)

set_slot("ANTHROPIC_DEFAULT_FABLE", fable_model, SLOT_VISIBLE_NAME["fable"])
set_slot("ANTHROPIC_DEFAULT_OPUS", opus_model, SLOT_VISIBLE_NAME["opus"])
set_slot("ANTHROPIC_DEFAULT_SONNET", sonnet_model, SLOT_VISIBLE_NAME["sonnet"])
set_slot("ANTHROPIC_DEFAULT_HAIKU", haiku_model, SLOT_VISIBLE_NAME["haiku"])

custom_alias = alias_by_model.get(custom_model, slug(custom_model))
env["ANTHROPIC_CUSTOM_MODEL_OPTION"] = custom_alias
env["ANTHROPIC_CUSTOM_MODEL_OPTION_NAME"] = f"{SLOT_VISIBLE_NAME['custom']} · {custom_model}"
env["ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION"] = f"{custom_model} via OpenCode Go / oc-go-cc"
env["ANTHROPIC_CUSTOM_MODEL_OPTION_SUPPORTED_CAPABILITIES"] = caps_for(custom_model)


# Global Claude Code personalization layer.
claude_dir = home / ".claude"
output_styles_dir = claude_dir / "output-styles"
themes_dir = claude_dir / "themes"
agents_dir = claude_dir / "agents"
for d in (output_styles_dir, themes_dir, agents_dir):
    d.mkdir(parents=True, exist_ok=True)

# Make Claude Code open in the user's preferred high-autonomy, high-signal UI mode.
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
parts = [f"{PURPLE}◆ {model_name}{RESET}", f"{CYAN}{folder}{RESET}"]
if branch:
    parts.append(f"{GREEN} {branch}{RESET}")
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

# Human-readable summary of installed personalization.
personalization_summary = claude_dir / "personalization-summary.txt"
personalization_summary.write_text('''Claude Code personalization installed by setup-claude-opencode-go.sh

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
  claude-ocgo         OpenCode Go gateway + bypassPermissions
  claude-truth        Normal Claude Code + bypassPermissions + personalization settings
  ocgo-routing-doctor Print alias -> exact model_id routing table

Recommended first Claude Code command:
  /config

Verify selected output style/theme if Claude Code version requires manual activation:
  /output-style
  /theme
  /statusline
''')

claude_path.write_text(json.dumps(data, indent=2) + "\n")

# Write manual model map.
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

# ── Intel Pack: slash commands ──────────────────────────────────────
commands_dir = home / ".claude" / "commands"
commands_dir.mkdir(parents=True, exist_ok=True)

(commands_dir / "tech-radar.md").write_text("""\
---
description: AI, software engineering, developer tooling, and GitHub repository intelligence brief
argument-hint: [optional focus, e.g. coding agents, Rust CLI tools, React, MCP, databases]
---

Use Tavily MCP first. Do not use built-in WebSearch for general search. Use GitHub MCP or gh CLI only when available and useful. Use WebFetch only for specific URLs after discovery.

You are my Tech Radar Intelligence Agent.

Mission:
Produce a high-signal intelligence briefing for AI + software engineering + new GitHub projects.

Default scope:
- AI: frontier models, coding agents, Claude Code, OpenAI, Anthropic, Google DeepMind, xAI, Meta AI, open-source models, local LLMs, inference, evals, benchmarks, MCP, agent frameworks
- Software engineering: TypeScript, React, TanStack, Electron, Bun, Node, Python, Rust, Go, databases, Postgres, SQLite, DX tools, CLIs, terminal tools, observability, testing, security, CI/CD
- GitHub discovery: new or fast-growing repos, useful libraries, devtools, agent tools, MCP servers, UI kits, infra tools, model tooling, data tools

User focus: $ARGUMENTS

Research workflow:
1. Search broadly with Tavily: latest AI news, latest software development news, GitHub trending, new repos, releases, changelogs, official blogs, Hacker News (secondary)
2. For GitHub discovery: GitHub Trending, recently created repos, meaningful README/code, active issues/releases, avoid toy repos and SEO spam
3. Extract important sources. Do not summarize headlines only. De-duplicate.
4. Classify each item: Importance (Critical/High/Medium/Low), Category (AI/CodingAgent/DevTool/Library/Framework/Infra/Security/Research/Business), Maturity (Production-ready/Promising/Experimental/Hype/Avoid), Confidence (High/Medium/Low)

Output in Turkish with sections: Executive Summary, Top AI Developments, Software Engineering/DevTool Developments, GitHub Repo Radar, Coding Agent/MCP Watch, Signal vs Noise, Action Items, Watchlist Queries For Next Run.

Rules: Cite sources. Prefer primary sources. Be skeptical. Do not pad. Do not use generic hype language.
""")

(commands_dir / "repo-radar.md").write_text("""\
---
description: Discover high-signal new and trending GitHub repositories
argument-hint: [topic/language/category]
---

Use Tavily MCP first. Use GitHub MCP or gh CLI when available. Do not use built-in WebSearch.

Mission: Find genuinely useful new, trending, or fast-growing GitHub repositories for the requested topic.

User focus: $ARGUMENTS

Default focus: AI agents, coding agents, MCP servers, Claude Code tooling, local LLM tooling, TypeScript devtools, React/TanStack/Radix UI, Electron/Bun, Rust CLI tools, Go backend tools, Python data/ML tools, databases, observability, testing, security.

Discovery queries: GitHub trending today/this week, topic-specific searches, recent releases/changelogs.

For each candidate inspect README/source/release activity. Score: Usefulness 1-10, Novelty 1-10, Code quality signal 1-10, Maintenance/activity 1-10, Hype risk Low/Medium/High, Fit for my stack Low/Medium/High.

Output sections: Top Picks (ranked table), Detailed Notes, Ignore/Low Signal, Install/Test Queue.
""")

(commands_dir / "dev-news.md").write_text("""\
---
description: Daily software development news and engineering trend brief
argument-hint: [optional focus]
---

Use Tavily MCP first. Do not use built-in WebSearch.

Create a concise but deep daily software engineering brief. Include: framework/library releases, language/runtime updates, security advisories, database/backend tooling, frontend/UI tooling, developer experience tools, GitHub projects worth tracking, AI tools only when they affect software development.

User focus: $ARGUMENTS

Output in Turkish with sections: Executive Summary, High-Impact Developer News, GitHub Projects Worth Watching, Security/Risk Notes, What I Should Test/Read/Install, What to Ignore, Watchlist for Next Run.

Be skeptical, cite sources, avoid hype.
""")

# ── Intel Pack: routing policy for CLAUDE.md ─────────────────────────
routing_block = '''\
<!-- TECH_RADAR_ROUTING_START -->
# Global intelligence routing policy

For current information, web search, news, GitHub discovery, software trend monitoring, package/version lookup, benchmark lookup, and public source discovery:

1. Use Tavily MCP first.
2. Use Tavily search/extract/crawl/map/research skills when available.
3. Use GitHub MCP or gh CLI for GitHub-specific repo/issue/release inspection when available.
4. Do not use built-in WebSearch for general discovery.
5. Use WebFetch only for specific URLs after discovery.
6. Prefer primary sources: official docs, release notes, GitHub repos/releases/issues, arXiv/papers, vendor blogs.
7. Treat community posts and SEO articles as secondary signal.
8. For GitHub repo recommendations, evaluate usefulness, maintenance, code quality signal, novelty, and hype risk.
9. Always separate signal from noise.
10. Use Turkish by default.

Preferred custom commands:
- /tech-radar for AI + software + GitHub overall intelligence
- /repo-radar for GitHub project discovery
- /dev-news for software engineering daily brief
<!-- TECH_RADAR_ROUTING_END -->
'''

upsert_managed_block(
    claude_dir / "CLAUDE.md",
    routing_block,
    "<!-- TECH_RADAR_ROUTING_START -->",
    "<!-- TECH_RADAR_ROUTING_END -->",
)

print("")
print("WROTE:")
print(f"  {oc_path}")
print(f"  {claude_path}")
print(f"  {model_list_path}")
print(f"  {commands_dir / 'tech-radar.md'}")
print(f"  {commands_dir / 'repo-radar.md'}")
print(f"  {commands_dir / 'dev-news.md'}")
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
PY

info "Creating launcher commands..."

cat > "$INSTALL_DIR/start-oc-go-cc" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
source "\$HOME/.config/oc-go-cc/env"
exec "$INSTALL_DIR/oc-go-cc" serve
EOF
chmod +x "$INSTALL_DIR/start-oc-go-cc"

cat > "$INSTALL_DIR/claude-ocgo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

unset ANTHROPIC_API_KEY
unset CLAUDE_CODE_OAUTH_TOKEN

export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
export ANTHROPIC_AUTH_TOKEN="unused"
export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY="1"
export CLAUDE_CODE_ALWAYS_ENABLE_EFFORT="1"
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"

# 5-slot model env vars (deterministic — do not rely on settings.json alone).
export ANTHROPIC_DEFAULT_FABLE_MODEL="claude-ocgo-minimax-m3"
export ANTHROPIC_DEFAULT_FABLE_MODEL_NAME="MiniMax M3 · minimax-m3"
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-ocgo-deepseek-v4-pro"
export ANTHROPIC_DEFAULT_OPUS_MODEL_NAME="DeepSeek V4 Pro · deepseek-v4-pro"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-ocgo-kimi-k2-7-code"
export ANTHROPIC_DEFAULT_SONNET_MODEL_NAME="Kimi K2.7 Code · kimi-k2.7-code"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-ocgo-deepseek-v4-flash"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME="DeepSeek V4 Flash · deepseek-v4-flash"
export ANTHROPIC_CUSTOM_MODEL_OPTION="claude-ocgo-qwen3-7-plus"
export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="Qwen3.7 Plus · qwen3.7-plus"

exec claude --permission-mode bypassPermissions "$@"
EOF
chmod +x "$INSTALL_DIR/claude-ocgo"

cat > "$INSTALL_DIR/claude-truth" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

exec claude --permission-mode bypassPermissions "$@"
EOF
chmod +x "$INSTALL_DIR/claude-truth"

cat > "$INSTALL_DIR/open-claude-desktop-ocgo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v launchctl >/dev/null 2>&1; then
  echo "launchctl not found; this launcher is for macOS Claude Desktop." >&2
  exit 1
fi

launchctl unsetenv ANTHROPIC_API_KEY 2>/dev/null || true
launchctl unsetenv CLAUDE_CODE_OAUTH_TOKEN 2>/dev/null || true

launchctl setenv ANTHROPIC_BASE_URL "http://127.0.0.1:3456"
launchctl setenv ANTHROPIC_AUTH_TOKEN "unused"
launchctl setenv CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY "1"
launchctl setenv CLAUDE_CODE_ALWAYS_ENABLE_EFFORT "1"
launchctl setenv CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS "1"

osascript -e 'quit app "Claude"' 2>/dev/null || true
sleep 2
open -a Claude
EOF
chmod +x "$INSTALL_DIR/open-claude-desktop-ocgo"

cat > "$INSTALL_DIR/ocgo-routing-doctor" <<'ROUTINGEOF'
#!/usr/bin/env bash
set -euo pipefail
OC_CONFIG="${HOME}/.config/oc-go-cc/config.json"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
OC_GO_CC_SOURCE_DIR="${OC_GO_CC_SOURCE_DIR:-$HOME/.local/src/oc-go-cc}"
if [[ ! -f "$OC_CONFIG" ]]; then
  echo "ERROR: $OC_CONFIG not found. Run the setup script first." >&2
  exit 1
fi
export OC_CONFIG CLAUDE_SETTINGS OC_GO_CC_SOURCE_DIR
python3 <<'PYEOF'
import json, os, sys
from pathlib import Path
cfg_path = Path(os.environ["OC_CONFIG"])
settings_path = Path(os.environ["CLAUDE_SETTINGS"])
cfg = json.loads(cfg_path.read_text())
settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
mo = cfg.get("model_overrides", {})

# The 5 desired Claude Code picker slots -> exact backend model_id.
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

import shutil, subprocess
binary = shutil.which("oc-go-cc") or "<not found in PATH>"
print(f"--- Installed oc-go-cc binary ---")
print(f"  {binary}")
print("")
print(f"--- Source repo / commit ---")
source_dir = os.environ["OC_GO_CC_SOURCE_DIR"]
if os.path.isdir(os.path.join(source_dir, ".git")):
    try:
        url = subprocess.check_output(["git", "-C", source_dir, "remote", "get-url", "origin"], stderr=subprocess.DEVNULL, text=True).strip()
        commit = subprocess.check_output(["git", "-C", source_dir, "rev-parse", "--short", "HEAD"], stderr=subprocess.DEVNULL, text=True).strip()
        branch = subprocess.check_output(["git", "-C", source_dir, "rev-parse", "--abbrev-ref", "HEAD"], stderr=subprocess.DEVNULL, text=True).strip()
        print(f"  source dir: {source_dir}")
        print(f"  origin    : {url}")
        print(f"  branch    : {branch}")
        print(f"  commit    : {commit}")
    except Exception as e:
        print(f"  source dir: {source_dir} (git query failed: {e})")
else:
    print(f"  source dir: {source_dir} (not a git checkout)")
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
PYEOF
ROUTINGEOF
chmod +x "$INSTALL_DIR/ocgo-routing-doctor"

info "Validating oc-go-cc config..."
if command -v oc-go-cc >/dev/null 2>&1; then
  source "$OC_CONFIG_DIR/env"
  oc-go-cc validate || warn "oc-go-cc validate failed. Check $OC_CONFIG_DIR/config.json"
else
  warn "oc-go-cc is not in PATH yet. Run: source ~/.zshrc or export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# ── Full Intel Pack ──────────────────────────────────────────────────
if [[ "$FULL_INTEL" == "1" ]]; then

TMPDIR_INTEL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_INTEL"' EXIT

info "Intel Pack: registering plugin marketplaces..."
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents 2>/dev/null || true

info "Intel Pack: installing official marketplace plugins..."
OFFICIAL_DIR="$TMPDIR_INTEL/claude-plugins-official"
if git clone --depth 1 https://github.com/anthropics/claude-plugins-official.git "$OFFICIAL_DIR" 2>/dev/null; then
  for plugin_dir in "$OFFICIAL_DIR"/plugins/*/ "$OFFICIAL_DIR"/external_plugins/*/; do
    [ -d "$plugin_dir" ] || continue
    manifest="$plugin_dir.claude-plugin/plugin.json"
    [ -f "$manifest" ] || continue
    name="$(python3 -c "import json; print(json.load(open('$manifest')).get('name', ''))" 2>/dev/null)"
    [ -z "$name" ] && name="$(basename "$plugin_dir")"
    [ -z "$name" ] && continue
    if ! claude plugin list 2>/dev/null | grep -Fq "$name"; then
      yes | claude plugin install "${name}@claude-plugins-official" --scope user 2>/dev/null && \
        claude plugin enable "${name}@claude-plugins-official" --scope user 2>/dev/null || true
    fi
  done
  ok "Intel Pack: official plugins installed"
else
  warn "Intel Pack: could not clone plugin marketplace (skipping)"
fi

info "Intel Pack: installing Tavily MCP..."
if ! claude mcp list 2>/dev/null | grep -iq "tavily"; then
  claude mcp add tavily-remote-mcp --scope user --transport http https://mcp.tavily.com/mcp/ 2>/dev/null && \
    ok "Intel Pack: Tavily MCP added" || \
    warn "Intel Pack: Tavily MCP failed (may need manual auth)"
fi

if ! command -v tvly >/dev/null 2>&1; then
  info "Intel Pack: installing Tavily CLI..."
  bash -lc 'curl -fsSL https://cli.tavily.com/install.sh | bash' 2>/dev/null || true
fi

info "Intel Pack: installing Tavily skills..."
npx -y skills add tavily-ai/skills --all 2>/dev/null || true

info "Intel Pack: installing VoltAgent subagents..."
VOLT_DIR="$TMPDIR_INTEL/awesome-claude-code-subagents"
if git clone --depth 1 https://github.com/VoltAgent/awesome-claude-code-subagents.git "$VOLT_DIR" 2>/dev/null; then
  count=0
  mkdir -p "$HOME/.claude/agents"
  for agent_file in "$VOLT_DIR"/*.md; do
    [ -f "$agent_file" ] || continue
    name="$(basename "$agent_file")"
    [ "$name" = "README.md" ] && continue
    head -c 200 "$agent_file" | grep -q "^---" || continue
    target="$HOME/.claude/agents/$name"
    [ -f "$target" ] && target="$HOME/.claude/agents/voltagent-$name"
    cp "$agent_file" "$target"
    count=$((count + 1))
  done
  ok "Intel Pack: $count VoltAgent subagents installed"
fi

info "Intel Pack: installing community slash commands..."
WS_DIR="$TMPDIR_INTEL/wshobson-commands"
if git clone --depth 1 https://github.com/wshobson/commands.git "$WS_DIR" 2>/dev/null; then
  count=0
  mkdir -p "$HOME/.claude/commands/community"
  for cmd_file in "$WS_DIR"/*.md; do
    [ -f "$cmd_file" ] || continue
    name="$(basename "$cmd_file")"
    [ "$name" = "README.md" ] && continue
    head -c 200 "$cmd_file" | grep -q "^---" || continue
    target="$HOME/.claude/commands/community/$name"
    [ -f "$target" ] && target="$HOME/.claude/commands/community/ws-$name"
    cp "$cmd_file" "$target"
    count=$((count + 1))
  done
  ok "Intel Pack: $count community commands installed"
fi

trap - EXIT
rm -rf "$TMPDIR_INTEL"

ok "Intel Pack: full intelligence pack installed"
else
  info "Intel Pack: skipped (--skip-intel)"
fi

ok "Done."
echo ""
echo "Next commands:"
echo ""
echo "  source ~/.config/oc-go-cc/env"
echo "  start-oc-go-cc"
echo ""
echo "In another terminal:"
echo ""
echo "  claude-ocgo"
echo ""
echo "Or, for normal Claude Code with your global personalization only:"
echo ""
echo "  claude-truth"
echo ""
echo "Inside Claude Code:"
echo ""
echo "  /clear opencode-go-test"
echo "  /model"
echo ""
echo "Personalization summary:"
echo ""
echo "  cat ~/.claude/personalization-summary.txt"
echo ""
echo "Manual model aliases:"
echo ""
echo "  cat ~/.claude/opencode-go-models.txt"
echo ""
echo "Verify routing table:"
echo ""
echo "  ocgo-routing-doctor"
echo ""
echo "For Claude Desktop on macOS:"
echo ""
echo "  start-oc-go-cc"
echo "  open-claude-desktop-ocgo"
echo ""
echo "Cache reset (run once after first install, or if routing looks wrong):"
echo ""
echo "  pkill -f 'oc-go-cc serve' || true"
echo "  pkill -f 'claude' || true"
echo "  rm -f ~/.claude/cache/gateway-models.json"
echo "  source ~/.config/oc-go-cc/env"
echo "  start-oc-go-cc"
echo ""
echo "Intel Pack commands (if --full-intel was enabled):"
echo ""
echo "  /tech-radar     AI, software, and GitHub intelligence brief"
echo "  /repo-radar     New and trending GitHub repos"
echo "  /dev-news       Daily software engineering news"
echo ""
echo "To skip Intel Pack on re-run:"
echo ""
echo "  ./setup-claude-opencode-go-personalized.sh --skip-intel ..."
