#!/bin/bash

# Parse possible commands
COMMANDS=`cdo help | grep -ohe '^\s\s\S\+'`
CDO_PATH="$(dirname `which cdo`)/src"

# Use compgen and friends to get possible matches
_commands()
{
  local cur prev words
  _get_comp_words_by_ref -n : cur prev words

  # Get command help if there is a full command
  if [[ ! -z ${words[1]} && ${cur} != ${words[1]} ]]; then
    ARGUMENTS=($(cdo help "${words[1]}" | grep -ohe '^\s\s\S\+'))
    ARGUMENT=${ARGUMENTS[0]}

    # Get rid of 'optional' markings ('[...]')
    ARGUMENT=${ARGUMENT//[\[\]]/}

    if [[ ${ARGUMENT} == COMMAND* ]]; then
      # This means the subcomponent is itself another command
      COMPREPLY=( $(compgen -W "${COMMANDS}" ${cur}) )
      __ltrim_colon_completions "$cur"
    elif [[ ${ARGUMENT} == FILE* ]]; then
      # Get any hint to the directory
      IFS=$':' PARTS=(${ARGUMENT})
      unset IFS

      ARGUMENT=${PARTS[0]}
      SEARCH_PATH=${PARTS[1]}

      if [ ! -z ${SEARCH_PATH} ]; then
        SEARCH_PATH="${CDO_PATH}"/"${SEARCH_PATH}"
        COMPREPLY=( $(compgen -f -- ${SEARCH_PATH}/"$cur") )

        # Drop prefix and ensure directories do not completely autocomplete
        i=0
        count="${#COMPREPLY[@]}"

        if [ ${count} == 1 ]; then
          # If it is a directory... do not allow a space
          if [ -d ${COMPREPLY[0]} ]; then
            compopt -o nospace
            COMPREPLY=( $(compgen -d -- ${SEARCH_PATH}/"$cur") )
          fi
        fi

        for reply in ${COMPREPLY[@]}; do
          if [ -d ${reply} ]; then
            reply="${reply}/"
          fi

          COMPREPLY[i++]=${reply#"${SEARCH_PATH}/"}
        done
      else
        # Turn off normal completion to allow the normal shell autocomplete, otherwise
        compopt -o default
        COMPREPLY=()
      fi
    fi
  else
    COMPREPLY=( $(compgen -W "${COMMANDS}" ${cur}) )
    __ltrim_colon_completions "$cur"
  fi
}

# Run auto-completion routine
complete -F _commands cdo ./cdo
