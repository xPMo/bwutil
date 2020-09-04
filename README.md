# Bitwarden Command-Line Utilities

Tools to easily manage your Bitwarden Vault on the command-line.

This is a personal project of me replacing my `pass`-based scripts with `bw`-based ones.

**Global Dependencies:**

- `zsh` ("The Programmer's Shell")
- `jq` (Command-line JSON parser)
- `bw` (Bitwarden CLI client)

## bw-edit

A tool to edit an item from your vault in your preferred editor.
Tests whether any edits occurred and verifies the json is valid before writing it back to the vault.

## bw-menu

Gets the list of item names to select from in fzf.
Takes a jq filter and a program as arguments;
the jq filter will be used to select the field
and the program will receive that field on stdin.

**Exmples:**

```sh
bin/bw-menu.zsh '.login.password' xclip -sel c
bin/bw-menu.zsh '.login|.username+"\t".password' ydotool type --file -
bin/bw-edit.zsh "$(bin/bw-menu.zsh '.id')"
```

## pass2bw:

A tool to import zx2c4 password store into Bitwarden.
It is rough around the edges,
since I wrote it for the way I use password-store.
Most of my files looked like this:

```
<password1>
user: <user>
otp: totp://<totp-info>
url: <some-site.com>
recovery codes: <recov1> <recov2> ...
SecurityQ1: <password2>
SecurityQ2: <password3>
```

Most files only had a password, or just a password and username.
The naming convention varied as well.

Anything beyond the first field containing the string `": "`
is interpreted as "key: value".
I have special handling for user, url and TOTP fields
since those are supported in BitWarden.


For usage, see `./pass2bw --help`.

