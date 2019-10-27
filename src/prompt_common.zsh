# Prompt implementation


autoload -U colors && colors # Enable colors in prompt

# Display user unless it is this user
DEFAULT_USER=${DEFAULT_USER:-Matthew}

# Display execution time if greater than this value (in seconds)
PROMPT_CMD_MAX_EXEC_TIME=${PROMPT_CMD_MAX_EXEC_TIME:-5}





###############################################################################
#                                      Git                                    #
###############################################################################

# Modify the colors and symbols in these variables as desired.
GIT_PROMPT_PREFIX="%{$fg[green]%}(%{$reset_color%}"
GIT_PROMPT_SUFFIX="%{$fg[green]%})%{$reset_color%}"
GIT_PROMPT_AHEAD="%{$fg[red]%}NUM↑%{$reset_color%}"
GIT_PROMPT_BEHIND="%{$fg[cyan]%}NUM↓%{$reset_color%}"
GIT_PROMPT_MERGING="%{$fg[magenta]%}⚡︎%{$reset_color%}"
GIT_PROMPT_UNTRACKED="%{$fg[red]%}●%{$reset_color%}"
GIT_PROMPT_MODIFIED="%{$fg[yellow]%}●%{$reset_color%}"
GIT_PROMPT_STAGED="%{$fg[green]%}●%{$reset_color%}"


# Show Git branch/tag, or name/rev with a warning if on detached head
prompt_git_branch() {
  local branch
  if branch="$(git symbolic-ref -q --short HEAD 2> /dev/null)"; then
    # HEAD points to a branch
    echo "%{$fg[yellow]%}$branch%{$reset_color%}"
  else
    # Detached head, either print whatever name we can get or a commit hash
    branch="$(git name-rev --name-only --no-undefined --always HEAD 2> /dev/null)"
    echo "%{$fg[red]%}detached %{$fg[yellow]%}$branch%{$reset_color%}"
  fi
}

# Show different symbols as appropriate for various Git repository states
prompt_git_state() {
  # Compose this value via multiple conditional appends.
  local GIT_STATE=""

  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    GIT_STATE=$GIT_STATE${GIT_PROMPT_AHEAD//NUM/$NUM_AHEAD}
  fi

  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    GIT_STATE=$GIT_STATE${GIT_PROMPT_BEHIND//NUM/$NUM_BEHIND}
  fi

  # Merge indicator and traffic light
  local GIT_STATE_2
  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n "$GIT_DIR" ] && test -r $GIT_DIR/MERGE_HEAD; then
    GIT_STATE_2=$GIT_STATE_2$GIT_PROMPT_MERGING
  fi

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    GIT_STATE_2=$GIT_STATE_2$GIT_PROMPT_UNTRACKED
  fi

  if ! git diff --quiet 2> /dev/null; then
    GIT_STATE_2=$GIT_STATE_2$GIT_PROMPT_MODIFIED
  fi

  if ! git diff --cached --quiet 2> /dev/null; then
    GIT_STATE_2=$GIT_STATE_2$GIT_PROMPT_STAGED
  fi

  # Add space to first part if second part is not empty
  if [[ -n $GIT_STATE && -n $GIT_STATE_2 ]]; then
    GIT_STATE="$GIT_STATE "
  fi

  # Concatenate first and second part, then print prepended with a space if not empty
  GIT_STATE="$GIT_STATE$GIT_STATE_2"
  if [[ -n $GIT_STATE ]]; then
    echo " $GIT_STATE"
  fi

}

# If inside a Git repository, print its branch and state
prompt_git_block() {
  local branch="$(prompt_git_branch)"
  if [ -n "$branch" ]; then
    echo "$GIT_PROMPT_PREFIX$branch$(prompt_git_state)$GIT_PROMPT_SUFFIX"
  fi
}





###############################################################################
#                                Execution time                               #
###############################################################################

# Turn seconds into human readable time
# 165392.5 => 1d21h56m32.5s
# From https://github.com/sindresorhus/pure/blob/master/pure.zsh
prompt_human_time_to_var() {
  local human total_seconds=$1 var=$2
  integer days=$(( total_seconds / 60 / 60 / 24 ))
  integer hours=$(( total_seconds / 60 / 60 % 24 ))
  integer minutes=$(( total_seconds / 60 % 60 ))
  typeset -F seconds=$(( total_seconds % 60 ))
  (( days > 0 )) && human+="${days}d"
  (( hours > 0 )) && human+="${hours}h"
  (( minutes > 0 )) && human+="${minutes}m"
  human+="$(printf '%.1fs' $seconds)"

  # Store human readable time in a variable as specified by the caller
  typeset -g "${var}"="${human}"
}

# Store (into prompt_cmd_exec_time) the execution time of the last command if
# set threshold was exceeded.
prompt_check_cmd_exec_time() {
  typeset -F elapsed
  (( elapsed = EPOCHREALTIME - ${prompt_cmd_timestamp:-$EPOCHREALTIME} ))
  typeset -g prompt_cmd_exec_time=
  (( elapsed > PROMPT_CMD_MAX_EXEC_TIME )) && {
    prompt_human_time_to_var $elapsed "prompt_cmd_exec_time"
  }
}

# Store timestamp when a command starts executing
prompt_time_preexec() {
  typeset -g prompt_cmd_timestamp=$EPOCHREALTIME
}

prompt_time_precmd() {
  # Check execution time and store it in a variable.
  prompt_check_cmd_exec_time
  unset prompt_cmd_timestamp
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt_time_precmd
add-zsh-hook preexec prompt_time_preexec

# Show execution time of last command if greater than PROMPT_CMD_MAX_EXEC_TIME seconds.
# Note: uses global variable.
prompt_exec_time_block() {
  if [[ -n "$prompt_cmd_exec_time" ]]; then
    # Need space or ⟳ overlaps time
    echo "⟳ $prompt_cmd_exec_time "
  fi
}





###############################################################################
#                               Everything else                               #
###############################################################################

# Show username if not the default user
prompt_user_block() {
  local user=$(whoami)

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    echo "%{$fg[magenta]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%}: "
  fi
}

# Print one section of the working directory
prompt_working_dir_part() {
  echo "%{$fg_bold[blue]%}$1%{$reset_color%}"
}

# Print the working directory, with git information inserted where appropriate
prompt_working_dir_block() {
  local len=${1-$#PWD}
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  local output=''
  if [[ -n $git_root ]]; then
    local git_root_parent=$git_root:h
    local git_root_name=$git_root:t
    # Recurse for each nested repo until we reach the top
    output=$(cd "$git_root_parent" && prompt_working_dir_block "$len")

    output+="$(prompt_working_dir_part /"$git_root_name") $(prompt_git_block)"
    wd=$(pwd -P)
    output+=$(prompt_working_dir_part "${wd##$git_root}")
  else
    if [[ -n $1 ]]; then
      # Have recursed out of a git repo
      output=$(prompt_working_dir_part "$(shrink_path "$PWD" "$len")")
    else
      # Not in a git repo at all
      output=$(prompt_working_dir_part "$(shrink_path)")
    fi
  fi
  echo "$output"
}

# Show the return value of the last command, if it wasn't zero
prompt_return_value_block() {
  echo "%(?..%{$fg[red]%}→%? %{$reset_color%})"
}

# Show the number of background jobs, if it isn't zero
prompt_jobs_block() {
  echo "%(1j.%{$fg[yellow]%}[%j+] %{$reset_color%}.)"
}

# Determine if we're running in a Docker container
# https://stackoverflow.com/a/23575107
running_in_docker() {
  [ -n "$(awk -F/ '$2 == "docker"' /proc/self/cgroup 2>/dev/null)" ]
}

prompt_docker_block() {
  if running_in_docker; then
    echo "(docker) "
  fi
}

# Prompt character: red # for root, $ otherwise
prompt_char() {
  echo "%(!.%{$fg[red]%}#%{$reset_color%}.$)"
}
