#!/usr/bin/env zsh

setopt warn_create_global extended_glob glob_dots

typeset -g default_note='Imported from password-store'
typeset -g item_template
typeset -gi debug_level
typeset -g help_text="Usage: $0 [OPTIONS] pass-name ...

OPTIONS:
	-A, --all               Import all passwords, ignore the commnd line pass-names
	    --session SESSION   Set BW_SESSION (see \`bw unlock --help\`)
	-n, --dry-run           Write out the json that would be passed to \`bw encode\`
	-v, --verbose           Increase verbosity
	-h, --help              Show this help
"

die(){
	print -u2 -l "${@:2}"
	exit "$1"
}
debug(){
	((debug_level > $1)) || return
	print -u2 "${@:2}"
}
convert_target(){
	# TODO: allow user-defined rules to convert path to name
	# e.g.: "site.com/name" -> "Site - Name"
	REPLY=$1
	
	return
	# One option:
	local MATCH MBEGIN MEND
	# replace slashes with " - ", split into words, capitalize first letter of each word
	# "foo bar/baz" -> "Foo Bar - Baz"
	REPLY=${${=1//\// - }/(#m)?/${MATCH:u}}

}

json_field(){ # name value [type=0]
	jq --null-input '{"name": $key, "value": $val, "type": ($type | tonumber)}' \
		--arg key "${1?$0: Missing parameter [KEY]}" \
		--arg val "${2?$0: Missing parameter [VAL]}" \
		--arg type "${3:-0}"
}
json_uri(){ # match uri
	jq --null-input '{"match": ($m | tonumber), "uri": $uri}' \
		--arg m "${1?$0: Missing parameter [MATCH]}" \
		--arg uri "${2?$0: Missing parameter [URI]}"
}

text_to_json::build(){
	# Use template from bw
	: ${item_template:="$(bw get template item)"}

	jq --null-input '$template
		| .name = $name | .notes = $note
		| .login = { "username": $user, "password": $pass, "totp": $totp, "uris": $uris}
		| .fields = $fields' \
		--arg name "$name" \
		--arg note "${(F)notes:-$default_note}" \
		--arg pass "$pass" \
		--arg user "$user" \
		--arg totp "$totp" \
		--argjson template "$item_template" \
		--argjson fields "[${(j[,])out_fields}]" \
		--argjson uris   "[${(j[,])out_uris}]" \
		|| die 1 "$0: Error in json"
}

text_to_json(){ # TARGET
	: ${1:?$0: Missing parameter [TARGET]}

	local REPLY
	convert_target "$1"
	local field totp user idx pass name=$REPLY
	local -a in_fields out_fields out_uris notes

	in_fields=(${(f)"$(pass show $1)"}) ||
		die 1
	pass=$in_fields[1]

	for ((idx = 2; idx <= $#in_fields; idx++)){
		field=$in_fields[idx]

		# test lowercase
		case ${field:l} in
			totpauth*|otpauth*)
				totp=$field ;;
			user:*|email:*|username:*|name:*|login:*)
				user=${field##[^:]#:[[:space:]]#} ;;
			(sec|back|reco)[^:]#:*)
				out_fields+=(
					"$(json_field 'Backup Codes' "${field##[^:]#:[[:space:]]#}")"
				) ;;
			host:*|url:*) # pass-ff uses regex for every url/host
				out_uris+=(
					"$(json_uri 4 "${field##[^:]#:[[:space:]]#}")"
				) ;;
			note[^:]#:*|info[^:]#:*)
				notes+=(${field##[^:]#:[[:space:]]$})
				;;
			git:*) # pass-git-helper
				# might be of form "git: user.key: val"
				# not much we can do about it...
				;&
			[^:]#:*)
				out_fields+=(
					"$(json_field "${(M)field##[^:]#}" "${field##[^:]#:[[:space:]]#}")"
				) ;;
			*) # isn't in form "key: val"
				if ((idx == 2)); then
					user=$field # assume second field is username
				else
					out_fields+=("$(json_field '' "$field")")
				fi
				;;
		esac
	}
	if (($#dry_run)); then
		text_to_json::build
	else
		text_to_json::build | bw encode | bw create item
	fi

}

# MAIN
(){
	local -a session help dry_run all flagv flagq keyctl gpg
	zmodload zsh/zutil
	zparseopts -D -E -F - \
		-session:=session \
		-dry-run=dry_run n=dry_run \
		-verbose+=flagv v+=flagv \
		-quiet+=flagq q+=flagq \
		-session-keyctl:=keyctl \
		-session-gpgagent:=gpg \
		-all=all A=all \
		-help=help h=help \
		|| die 1 "$help_text"
	
	(($#help)) &&
		die 0 "$help_text"

	((debug_level = $#flagv - $#flagq))

	if (($#all)); then
		local dir=${${PASSWORD_STORE_DIR-$HOME/.password-store}:-$PWD}
		# get every gpg file
		set -- $dir/**/*.gpg
		# remove prefix
		set -- ${@##$dir/#}
		# remove suffix
		set -- ${@%.gpg}
		# test if pass works with the first file
		pass show "$1" >/dev/null 2>&1 ||
			die 1 "No password directory found at $dir"
	fi

	# unlock vault if not already
	[[ $session ]] &&
		export BW_SESSION=$session[-1]
	bw unlock --raw --check ||
		export BW_SESSION=$(bw unlock --raw < $TTY)
	local arg
	for arg;{
		debug 1 "Inserting password: $arg"
		text_to_json "$arg"
	}
} "$@"
