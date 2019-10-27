# Zsh prompt
#
# Based on tjkirch  (https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/tjkirch.zsh-theme)
# Username hiding from agnoster  (https://gist.github.com/agnoster/3712874)
# Git status based on https://gist.github.com/joshdick/4415470
# -- Shows number of commits to push/pull, merge status, traffic lights for untracked/modified/staged
# Execution time from pure  (https://github.com/sindresorhus/pure)

# shellcheck disable=SC1090,SC2034,SC2016


# https://stackoverflow.com/a/28336473
# https://unix.stackexchange.com/a/115431
0="${(%):-%x}"
__MJE_THEME_DIR="$0:A:h"
source "$__MJE_THEME_DIR/src/shrink_path.zsh"
source "$__MJE_THEME_DIR/src/prompt_common.zsh"


# TODO: Tweak colours? Blue is often hard to see

PROMPT='$(prompt_user_block)$(prompt_working_dir_block)
%_$(prompt_return_value_block)$(prompt_jobs_block)$(prompt_exec_time_block)$(prompt_docker_block)$(prompt_char) '

# TODO: PROMPT2 from Pure
# TODO: set title from Pure
# TODO: privatise variables
# TODO: case-insensitive user check
# TODO: is SSH_CONNECTION reliable?
# TODO: DEFAULT_MACHINE?
# TODO: Silence shellcheck warnings
# TODO: faster git checks
