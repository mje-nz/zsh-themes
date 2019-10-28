# Zsh prompt
#
# Based on tjkirch  (https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/tjkirch.zsh-theme)
# Username hiding from agnoster  (https://gist.github.com/agnoster/3712874)
# Git status based on https://gist.github.com/joshdick/4415470
# -- Shows number of commits to push/pull, merge status, traffic lights for untracked/modified/staged
# Execution time and contiuation prompt from pure (https://github.com/sindresorhus/pure)

# shellcheck disable=SC1090,SC2034,SC2016

# https://stackoverflow.com/a/28336473
# https://unix.stackexchange.com/a/115431
0="${(%):-%x}"
__MJE_THEME_DIR="$0:A:h"
source "$__MJE_THEME_DIR/src/shrink_path.zsh"
source "$__MJE_THEME_DIR/src/prompt_common.zsh"


# Print the working directory
prompt_working_dir_block_fast() {
  typeset -gA __PROMPT_WORKING_DIR_BLOCK_CACHE
  if (( ${+__PROMPT_WORKING_DIR_BLOCK_CACHE["$PWD"]} == 1 )); then
    # Full working dir block is in cache
    echo "${__PROMPT_WORKING_DIR_BLOCK_CACHE["$PWD"]}"
  else
    # Just print current path
    prompt_working_dir_part "$(shrink_path)"
  fi
}

prompt_precmd() {
  # TODO: Tweak colours? Blue is often hard to see

  # Render fast prompt
  # shellcheck disable=SC2016
  PROMPT='$(prompt_user_block)$(prompt_working_dir_block_fast)
%_$(prompt_return_value_block)$(prompt_jobs_block)$(prompt_exec_time_block)$(prompt_docker_block)$(prompt_venv_block)$(prompt_char) '

  # Start async job to render full prompt (no harm calling these repeatedly)
  # Note worker doesn't share environment so any variables needed must be passed in
  async_init
  async_start_worker prompt -n
  async_register_callback prompt prompt_async_update_complete
  async_job prompt prompt_async_working_dir_block "$PWD"
}
add-zsh-hook precmd prompt_precmd

# Render working dir block with git info in async worker
prompt_async_working_dir_block() {
  cd "${1}" || return
  echo "$1"
  prompt_working_dir_block
}

# Update prompt with async result
prompt_async_update_complete() {
  # Get output from worker
  local output=("${(f)3}")
  local working_dir="${output[1]}"
  local working_dir_block="${output[2]}"

  # Cache working dir block
  typeset -gA __PROMPT_WORKING_DIR_BLOCK_CACHE
  __PROMPT_WORKING_DIR_BLOCK_CACHE["$working_dir"]="$working_dir_block"

  # Update prompt
  # shellcheck disable=SC2016
  PROMPT='$(prompt_user_block)$working_dir_block
%_$(prompt_return_value_block)$(prompt_jobs_block)$(prompt_exec_time_block)$(prompt_docker_block)$(prompt_venv_block)$(prompt_char) '
  zle && zle reset-prompt
}

# Continuation prompt
PROMPT2='%F{242}%_… %f> '
