#compdef cdo

# zsh completion for cdo            -*- shell script -*-

# Basic autoload of completion things
autoload -U +X compinit && compinit

# Get the path of the cdo repository
local CDO_PATH="$(dirname `which cdo`)/src"

# Get a list of commands and their descriptions
# This also replaces ':' in the commands with an escaped '\\\:' which allows
# zsh to understand that the subcommand's colon is not a separator
# Otherwise, it looks for 'command:description' in an array.
local COMMANDS=`cdo help | grep -ohe '^\s\s\S\+\s\+.\+$' | sed -e 's/^\s\s//' -e 's/:/\\\:/' -e 's/\(\S\)\s\+/\1:/'`

# Form the array of subcommands
local -a subcmds
subcmds=("${(f)COMMANDS}")

local cur=${words[-1]}
local index=$((${#words[@]} - 2))

if [[ ! -z ${words[2]} && ${cur} != ${words[2]} ]]; then
  local ARGUMENTS=($(cdo help "${words[2]}" | grep -ohe '^\s\s\S\+'))
  local ARGUMENT=${ARGUMENTS[${index}]}

  # Get rid of 'optional' markings ('[...]')
  ARGUMENT=${ARGUMENT//[\[\]]/}

  if [[ ${ARGUMENT} == COMMAND* ]]; then
    _describe 'command' subcmds
  elif [[ ${ARGUMENT} == FILE* ]]; then
    # Get any hint to the directory
    local PARTS=("${(@s[:])ARGUMENT}")

    ARGUMENT=${PARTS[1]}
    SEARCH_PATH=${PARTS[2]}

    _files -W ${CDO_PATH}/${SEARCH_PATH}
  elif [[ ${ARGUMENT} == STRING* ]]; then
    # String type... no completion
    cur=${cur}
  elif [[ ${ARGUMENT} == INT* ]]; then
    # Integer... only digits
    cur=${cur}
  else
    # The listing is delimited by '|'
    local -a enumcmds
    enumcmds=("${(@s[|])ARGUMENT}")
    _describe 'command' enumcmds
  fi
else
  # The initial command listing
  _describe 'command' subcmds
fi
