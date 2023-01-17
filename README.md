# [DuckDNS.sh](https://github.com/BeyondCodeBootcamp/DuckDNS.sh)

A Posix Shell Script (Bash-compatible) for tracking your IP address
(at home, or on devices).

# Table of Contents

- ⚡️ Install
- 💪 Usage
- 👩‍🏫 Examples
- ⚙️ Configure
- 🔴 Watch the Live-Stream
- 📄 License

# Install

Both install methods are fairly similar.

## via [Webi](https://webinstall.dev/)

```sh
curl -sS https://webi.sh/duckdns.sh@v1 | sh
source ~/.config/envman/PATH.env
```

## via Git Assets

```sh
my_branch="v1"

mkdir -p ~/bin/

curl -fsSL -o ~/bin/duckdns.sh \
    "https://raw.githubusercontent.com/BeyondCodeBootcamp/DuckDNS.sh/${my_branch}/duckdns.sh"

chmod a+x ~/bin/duckdns.sh
```

# Usage

```text
USAGE
    duckdns.sh <subcommand> [arguments...]

SUBCOMMANDS
    myip                         - show this device's ip(s)
    ip <subdomain>               - show subdomain's ip(s)

    list                         - show subdomains
    auth <subdomain>             - add Duck DNS token
    update <subdomain>           - update subdomain to device ip
    set <subdomain> <ip> [ipv6]  - set ipv4 and/or ipv6 explicitly
    clear <subdomain>            - unset ip(s)
    run <subdomain>              - check ip and update every 5m
    enable <subdomain>           - enable on boot (Linux) or login (macOS)
    disable <subdomain>          - disable on boot or login

    help                         - show this menu
```

# Examples

```sh
duckdns.sh myip
duckdns.sh ip foo

duckdns.sh list
duckdns.sh auth foo

duckdns.sh update foo
duckdns.sh set foo 127.0.0.1
duckdns.sh set foo ::1
duckdns.sh set foo 127.0.0.1 ::1
duckdns.sh clear foo

duckdns.sh run foo
duckdns.sh enable foo
duckdns.sh disable foo
```

# Configure

You'll need to create your account, subdomain, and token before you can use `duckdns.sh`.

1. Login to <https://duckdns.org> and create a subdomain, such as `CHANGE-ME` for `CHANGE-ME.duckdns.org`
2. Copy your DNS Token
3. Create your subdomain token env file:

    ```sh
    duckdns.sh auth CHANGE_ME
    ```

    or

    ```sh
    # create the env file
    mkdir -p ~/.config/duckdns.sh/
    touch ~/.config/duckdns.sh/CHANGE_ME.env

    # write your token to the env file
    vim ~/.config/duckdns.sh/CHANGE_ME.env
    ```

    ```text
    DUCKDNS_TOKEN=xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx
    ```

# Watch

The making of this project was completely live-streamed (aside from one or two small typo edits that were done off-camera).

The first two videos are the project.

The third is adding version info and publishing to [webi](https://webinstall.dev).

<a href="https://www.youtube.com/playlist?list=PLxki0D-ilnqYdJDMOgwSnGtc03FeyNeVb"><kbd><img width="782" alt="YouTube Thumbnail" src="https://user-images.githubusercontent.com/122831/212806190-4d6cb441-03cb-4a3b-8a4c-ade659017693.png"></kbd></a>

# License

CC0-1.0 (Public Domain) \
See <https://creativecommons.org/publicdomain/zero/1.0/>.
