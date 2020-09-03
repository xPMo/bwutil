#!/usr/bin/env zsh
#
umask 066
TMPPREFIX=${XDG_RUNTIME_DIR:-/tmp}/bw-edit/}
TMPSUFFIX=.json

zmodload zsh/files
mkdir $TMPPREFIX

trap EXIT 'rm -r $TMPPREFIX'

(){
	local id
	cp $1 $1.bak
	while :; do
		$=VISUAL $1
		if diff --color=auto "$1" "$1.bak"; then
			read -k 1 'REPLY?No edits made. Try again(Y), insert anyway(n), or exit(e)?'
			case $REPLY:l in
				n) break ;;
				e) return 1 ;;
				*) continue ;;
			esac
		fi

		# Check for well-formed json
		if ! id=$(jq .id -r < "$1"); then
			read -k 1 'REPLY?Ill-formatted json. Try again(Y), insert anyway(n), or exit(e)?'
			case $REPLY:l in
				n) break ;;
				e) return 1 ;;
				*) continue ;;
			esac
		fi
		break
	done
	set -x
	bw encode < "$1" | bw edit "$2" "$id"
} =(bw get "$@" | jq) "$@"
