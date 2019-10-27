#!/usr/bin/env zsh

# Shrink directory paths, e.g. /home/me/foo/bar/quux -> ~/f/b/quux.
# Based on https://github.com/robbyrussell/oh-my-zsh/blob/c09323098acb03a0678f87036fad10bd99b283b2/plugins/shrink-path/shrink-path.plugin.zsh
# Copyright (C) 2008 by Daniel Friesel <derf@xxxxxxxxxxxxxxxxxx>
# License: WTFPL <http://sam.zoy.org/wtfpl>
#
# Ref: http://www.zsh.org/mla/workers/2009/msg00415.html
#      http://www.zsh.org/mla/workers/2009/msg00419.html

shrink_path () {
    # Usage: shrink_path [PATH [ACTUAL_LENGTH]]
    # PATH: Path to shrink (otherwise working directory)
    # ACTUAL_LENGTH: If provided, treat the given path as part of a longer path
    setopt localoptions
    setopt null_glob

    typeset -a tree expn
    typeset result part dir=${1-$PWD} full_len=$2
    typeset -i i

    [[ -d $dir ]] || return 0

    # Substitute named directories
    for part in ${(k)nameddirs}; {
        [[ $dir == ${nameddirs[$part]}(/*|) ]] && dir=${dir/${nameddirs[$part]}/\~$part}
    }

    # Substitute home directory
    dir=${dir/$HOME/\~}

    # If the result is less than 40 characters long, just print it
    # (overridden with first command line arg if present)
    if [[ ${full_len-$#dir} -lt 40 ]] {
        echo $dir
        return
    }

    # Shorten path
    tree=(${(s:/:)dir})
    (
        unfunction chpwd 2> /dev/null
        if [[ $tree[1] == \~* ]] {
            cd ${~tree[1]}
            result=$tree[1]
            shift tree
        } else {
            cd /
        }
        for dir in $tree; {
            # Use the full name of the last directory, unless part of a longer path
            if [[ -z $full_len && (( $#tree == 1 )) ]] {
                result+="/$dir"
                break
            }
            # Don't shrink folders with spaces in the name (it gets confusing)
            if [[ $dir == *' '* ]] {
                result+="/$dir"
            } else {
                expn=(a b)
                part=''
                i=0
                # Loop until part only expands to one directory or is the whole directory name
                until [[ (( ${#expn} == 1 )) || $dir = $expn || $i -gt $#dir ]]  do
                    (( i++ ))
                    part+=$dir[$i]
                    expn=($(echo ${part}*(-/)))
                done

                # If the abbreviation is almost the whole name, just use the whole name
                if (( $#dir - $i <= 2 )) {
                    part=$dir
                }

                result+="/$part"
            }
            cd $dir
            shift tree
        }
        echo ${result:-/}
    )
}
