# Powerlevel10k config: exact Starship look
#
# Matches configs/starship/starship.toml visually:
#   Line 1: ┌──[ directory ] git_branch git_status ⎈ k8s_context:ns python go node cmd_duration
#   Line 2: └─$
#   Right:  (only background_jobs visible; time/status disabled in Starship)
#
# All segments: transparent background, colored text only (lean style).
# Colors use ANSI 0-15 so they match whatever Ghostty/terminal theme is active (Catppuccin Macchiato).
#
# Sources the official p10k lean config for the git formatter and sane defaults,
# then overrides everything that differs from Starship.

# --- Load lean base (git formatter, completion, defaults) ---
P10K_LEAN="${POWERLEVEL9K_INSTALLATION_DIR:-$HOME/.zsh/themes/powerlevel10k}/config/p10k-lean.zsh"
[[ -r "$P10K_LEAN" ]] && source "$P10K_LEAN"

# ============================================================================
# Segment layout (matches Starship format string exactly)
# ============================================================================

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  # === Line 1 ===
  dir                       # $directory
  vcs                       # $git_branch + $git_status (p10k combines them)
  kubecontext               # $kubernetes
  virtualenv                # $python (virtualenv portion)
  go_version                # $golang
  node_version              # $nodejs
  command_execution_time    # $cmd_duration
  # === Line 2 ===
  newline                   # $line_break
  prompt_char               # └─$character
)

# Starship right_format = "$time$jobs$status$localip"
# time: disabled, status: disabled, localip: ssh_only (p10k has no localip segment)
# So only background_jobs is visible.
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  background_jobs
)

# ============================================================================
# Box drawing: ┌──[ dir ] ... / └─$
# ============================================================================

# Blank line before each prompt (Starship: add_newline = true)
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# Line 1: ┌──[ before dir, ] after dir -- brackets in default fg, dir in blue
# MULTILINE prefix is outside segments, rendered in default terminal foreground.
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='┌──[ '
typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
# ] after directory: use CONTENT_EXPANSION to append ] in default fg (%f resets color)
typeset -g POWERLEVEL9K_DIR_PREFIX=
typeset -g POWERLEVEL9K_DIR_SUFFIX=

# Line 2: └─ before $
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='└─'
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

# No right-side connectors
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

# Right prompt end
typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=

# ============================================================================
# Transparent backgrounds everywhere (lean style, like Starship)
# ============================================================================
typeset -g POWERLEVEL9K_BACKGROUND=                                    # global transparent
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=          # no extra whitespace
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '          # space between segments
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=                # no powerline arrows

# ============================================================================
# Segment styles -- ANSI colors 0-15 to match terminal theme
# ============================================================================
# ANSI color reference (Catppuccin Macchiato in Ghostty):
#   1=red  2=green  3=yellow  4=blue  6=cyan  8=bright-black(grey)
#  10=bright-green  14=bright-cyan  15=bright-white(text)

# --- prompt_char: Starship success=[\\$](bold)  error=[\\$](bold red) ---
# "bold" alone = bold + default foreground. p10k needs a color, use 15 (text/bright-white).
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=15
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=1
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
typeset -g POWERLEVEL9K_PROMPT_CHAR_VISUAL_IDENTIFIER_EXPANSION=

# --- dir: Starship style="blue" (ANSI 4), truncation_length=3, truncate_to_repo ---
typeset -g POWERLEVEL9K_DIR_FOREGROUND=4
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=4
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=4
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=false
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
typeset -g POWERLEVEL9K_DIR_VISUAL_IDENTIFIER_EXPANSION=              # no folder icon
# Append " ]" in default foreground after the blue directory path
typeset -g POWERLEVEL9K_DIR_CONTENT_EXPANSION='${P9K_CONTENT}%f ]'

# --- vcs (git): Starship git_branch=bright-black(8), git_status=cyan(6) ---
# p10k combines branch+status into one vcs segment.
# The lean git formatter uses its own internal colors; override the segment-level colors.
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=8
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=6
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=6
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=8
typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=8
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=              # no git icon, Starship has none

# --- kubecontext: Starship [$symbol](blue) [$context](bold cyan)[:$namespace] ---
# TRANSPARENT background (no pill). ⎈ icon in blue, text in bold cyan.
# Must UNSET, not set to empty. Empty = "show on no command" = never show.
# Lean config sets it to 'kubectl|helm|...'; unsetting = always show.
unset POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND
typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=14              # bold/bright cyan for text
typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_BACKGROUND=                # transparent (no pill!)
typeset -g POWERLEVEL9K_KUBECONTEXT_VISUAL_IDENTIFIER_EXPANSION='⎈'
typeset -g POWERLEVEL9K_KUBECONTEXT_VISUAL_IDENTIFIER_COLOR=4          # blue for the ⎈
# Starship format: context:namespace (show namespace after colon, hide "default")
typeset -g POWERLEVEL9K_KUBECONTEXT_CONTENT_EXPANSION='${P9K_KUBECONTEXT_CLOUD_CLUSTER:-${P9K_KUBECONTEXT_NAME}}${${:-/${P9K_KUBECONTEXT_NAMESPACE}}:#/default}'
typeset -g POWERLEVEL9K_KUBECONTEXT_PREFIX=                            # no prefix
typeset -g POWERLEVEL9K_KUBECONTEXT_CLASSES=(
  '*'  DEFAULT  ''
)

# --- command_execution_time: Starship style="yellow"(3), min_time=300ms ---
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0.3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=2
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION=  # no icon

# --- python/virtualenv: Starship style="bright-black"(8) ---
typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=8
typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=        # no icon (Starship shows name only)

# --- golang: Starship style="bright-cyan"(14), symbol="🐹 " ---
typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=14
typeset -g POWERLEVEL9K_GO_VERSION_VISUAL_IDENTIFIER_EXPANSION='🐹'

# --- nodejs: Starship style="bright-green"(10), symbol="⬢ " ---
typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=10
typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_EXPANSION='⬢'

# --- background_jobs: Starship style="bright-black"(8), symbol="✦ " ---
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=8
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='✦'

# ============================================================================
# Disabled / hidden (match Starship disabled=true)
# ============================================================================
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR=false
typeset -g POWERLEVEL9K_TIME_FOREGROUND=8
typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true

# Gap filler between left and right on line 1 (just spaces, not dots)
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '
