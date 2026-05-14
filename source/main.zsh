#!/usr/bin/env zsh

clean_hist() {

  local -ra _hist_ignore_cmds=(
    's'                  # `git status`
    'e(cho)?'            # `e`  `echo`
    'fc -e -'
    'c?l[-0]?'           # `l`  `l-`  `l0`  `cl`  `cl-`  `cl0`
    'c?h|c(lear_half)?'  # `h`  `ch`  `c`   `clear_half`

    # if a cmd consists only of the characters `c`, `r`, `;`, and whitespace:
    #  `r`  `c;r`  `rr;r`  `rr;c;r`  `c; rrr; r`  `cr`  `c \n rr`  ....
    '[[:space:]cr;]+'

    # `source .zshrc`  `. ./path/to/zshrc.zsh`  `. ~/$ZDOTDIR/.zshrc`  ....
    "(source|[.]).*zshrc([.]zsh)?[\"']?"

    '.*neofetch_startup_handler.*'
  )

  export _HIST_IGNORE_REGEX="^(${(j:|:)_hist_ignore_cmds})[[:space:]]*$"


  local -r NL=$'\n' HT=$'\t' BSL='\'

  local -r source_file='../tests/orig-2'
  local -r output_file='../tests/output'

  local data="$(< "$source_file" )"

  data="${data//[ $HT]$NL/$NL}"
  data="${(*)data//(\\$NL)##$NL/$NL}"
  data="${(*)data//;(\\$NL)##/;}"

  # ————————————————————————————————————————————————————————————————————————— #

  local -r first_line="${data%%$'\n'*}"
  local -r last_line="${data##*$'\n': }"

  local    first_time="${${first_line#: }%%:*}"
  local -r last_time="${last_line%%:*}"

  first_time="${(l:$#last_time::0:)first_time}"

  local -i 10 i
  for i ({1..$#first_time}) if [[ $first_time[i] != $last_time[i] ]] break

  local -ri 10 time_prefix=$first_time[1,i-1]

  # ————————————————————————————————————————————————————————————————————————— #

  local -r split_at="$NL: $time_prefix"
  local -a entries=( "${(@ps:$split_at:)data/#/$NL}" )
  entries=( "$time_prefix${(@)^entries[2,-1]}" )

  echo "${#entries}"

  local -a output_entries

  # timestamp="${entry%%:*}"
  # elapsed="${${entry%%;*}#*:}"

  setopt extended_glob

  local entry command orig_cmd pre_cmd
  local prev_cmd=

  for entry in "${(@)entries}"; {
    pre_cmd="${entry%%;*}"
    command="${(*)entry/#${pre_cmd};[ $HT]#}"

    if [[ "$command" =~ $_HIST_IGNORE_REGEX ]] continue

    orig_cmd="$command"
    command="${command//[[:space:]]}"

    if (( $#command  <=  1                )) continue
    if [[ "$command" == (exit|bye|logout) ]] continue

    output_entries+=": $pre_cmd;$orig_cmd"
  }

  echo ${#output_entries}

  # ————————————————————————————————————————————————————————————————————————— #

  local -a looping_arr
  local -a append_arr=( "${(@)output_entries}" )

  until (( $#append_arr == $#looping_arr )) {
    echo "appd = $#append_arr    loop = $#looping_arr"
    looping_arr=( "${(@)append_arr}" )
    append_arr=()

    for entry in "${(@)looping_arr}"; {
      command="${entry#*;}"
      if [[ "$command" != "$prev_cmd" ]] append_arr+="$entry"
      prev_cmd="$command"
    }
  }
  # echo "appd = $#append_arr    loop = $#looping_arr"
  echo ${#append_arr}

  # ————————————————————————————————————————————————————————————————————————— #

  looping_arr=( )
  local entry1 entry2 command1 command2 prev_cmd1 prev_cmd2


  until (( $#append_arr == $#looping_arr )) {
    echo "appd = $#append_arr    loop = $#looping_arr"

    looping_arr=( "${(@)append_arr}" )
    append_arr=()

    for entry1 entry2 in "${(@)looping_arr}"; {

      command1="${entry1#*;}"
      command2="${entry2#*;}"

      if [[ "$command1" != "$prev_cmd1" || "$command2" != "$prev_cmd2" ]] {
        prev_cmd1="$command1"
        prev_cmd2="$command2"
        append_arr+=( "$entry1" "$entry2" )
        continue
      }

      # echo -E "$command1 == $prev_cmd1"
      # echo -E "$command2 == $prev_cmd2"; echo

      prev_cmd1="$command1"
      prev_cmd2="$command2"
    }

  }

  # echo "appd = $#append_arr    loop = $#looping_arr"
  echo ${#append_arr}

  # ————————————————————————————————————————————————————————————————————————— #

  echo -nE "${(F)append_arr}" > "$output_file-2"
}

# {
#   if [[ "$command"  == "$prev_cmd_2" && "$prev_cmd" == "$prev_cmd_3" ]] {
#     output_entries[-1]=()
#     continue
#   }
#
#   if [[ "$command" == "$prev_cmd" ]] continue
#
# } always {
#   prev_cmd_3="$prev_cmd_2"
#   prev_cmd_2="$prev_cmd"
#   prev_cmd="$command"
# }

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] clean_hist "$@"