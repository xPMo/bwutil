# Bitwarden Command-Line Utilities

Tools to easily manage your Bitwarden Vault on the command-line.

This is a personal project of me replacing my `pass`-based scripts with `bw`-based ones.

**Global Dependencies:**

- `zsh` ("The Programmer's Shell")
- `jq` (Command-line JSON parser)
- `bw` (Bitwarden CLI client)

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

