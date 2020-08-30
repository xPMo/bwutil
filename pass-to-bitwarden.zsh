#!/usr/bin/env zsh

setopt warn_create_global extended_glob

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

text_to_json(){ # TARGET
	: ${1:?$0: Missing parameter [TARGET]}
	convert_target $1
	local pass_target=$1 bw_target=$REPLY
	local -a in_fields=(${(f)"$(pass show $1)"})
	local -a out_fields out_uris
	local pass=$in_fields[1]
	local field totp user revdate idx

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

	bw get template item |
	jq '.login = { "username": $user, "password": $pass, "totp": $totp, "uris": $uris} | .fields = $fields' \
		--arg pass "$pass" \
		--arg user "$user" \
		--arg totp "$totp" \
		--argjson fields "[${(j[,])out_fields}]" \
		--argjson uris   "[${(j[,])out_uris}]"
}

help(){
}

# MAIN
(){
	local -a
	zmodload zsh/zutil
	zparseopts -D -E -F - \
		-session=session \
		-help=help h=help \
	
	# unlock vault if not already
	[[ $session ]] &&
		export BW_SESSION=$session
	bw unlock --check ||
		export BW_SESSION=$(bw unlock --raw)
}
