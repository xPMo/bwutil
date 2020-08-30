#!/usr/bin/env zsh

setopt warn_create_global extended_glob

typeset -g default_note='Imported from password-store'
typeset -g item_template

convert_target(){
	# TODO: allow user-defined rules to convert path to name
	# e.g.: "site.com/name" -> "Site - Name"
	typeset -g REPLY=$1
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
		--argjson uris   "[${(j[,])out_uris}]"
}

text_to_json(){ # TARGET
	: ${1:?$0: Missing parameter [TARGET]}
	convert_target $1
	local pass_target=$1 name=$REPLY
	local -a in_fields=(${(f)"$(pass show $1)"})
	local -a out_fields out_uris notes
	local pass=$in_fields[1]
	local field totp user idx

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
	if [[ -n $dry_run ]]; then
		text_to_json::build
	else
		text_to_json::build | bw encode | bw create item
	fi

}

# MAIN
(){
	local -a session help
	zmodload zsh/zutil
	zparseopts -D -E -F - \
		-session=session \
		-help=help h=help \
	
	# unlock vault if not already
	[[ $session ]] &&
		export BW_SESSION=$session
	bw unlock --raw --check ||
		export BW_SESSION=$(bw unlock --raw < $TTY)
	local arg
	for arg;{
		text_to_json "$arg"
	}
} "$@"
