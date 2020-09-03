#!/bin/sh

# Usage: $0 jq-filter program [args ...]

# Examples:
#  .login.username xsel -b
#  .id bw encode
# '.login|.username+"\t"+.password' ydotool type --file -

tab='	' jq_filter=$1 item='' ret=''

die(){
	printf >&2 '%s\n' "$@"
	exit 1
}

shift ||
	die 'Missing argument.'

items=$(bw list items) ||
	die "bw could not list items."

# printf is a builtin, and so has a better chance to accept large argument lengths
item=$(printf '%s\n' "$items" | jq '.[].id+"\t"+.login' | fzf --with-nth=2..) ||
	die "No item selected."

ret=$(bw get item "${item%%$tab*}" | jq -rje "$jq_filter") ||
	die "jq returned non-zero exit code: $?" "Does the field $jq_filter exist for ${item%*$tab}?"

printf '%s' "$ret" | "$@"
