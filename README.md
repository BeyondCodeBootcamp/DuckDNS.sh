# [DuckDNS.sh](https://github.com/BeyondCodeBootcamp/DuckDNS.sh)

A Posix Shell Script (Bash-compatible) for tracking your IP address
(at home, or on devices).

# Install

```sh
mkdir -p ~/bin/
curl -fsSL -o ~/bin/duckdns.sh https://raw.githubusercontent.com/BeyondCodeBootcamp/DuckDNS.sh/main/duckdns.sh
chmod a+x ~/bin/duckdns.sh
```

# Configure

You'll need to create your account, subdomain, and token before you can use `duckdns.sh`.

1. Login to <https://duckdns.org>
2. Create a subdomain, such as `CHANGE-ME` for `CHANGE-ME.duckdns.org`
3. Copy your DNS Token
4. Create your subdomain token file:
    ```sh
    mkdir -p ~/.config/duckdns.sh/
    touch ~/.config/duckdns.sh/CHANGE_ME.env
    ```
5. Place your token in the file as `DUCKDNS_TOKEN=xxxxxxxx-YOUR-TOKEN...`:
    ```sh
    vim ~/.config/duckdns.sh/CHANGE_ME.env
    ```
    ```text
    DUCKDNS_TOKEN=xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx
    ```

# Usage

```sh
~/bin/duckdns.sh run <subdomain>
```

# Examples

```sh
~/bin/duckdns.sh run foo      # periodically check ip address and update subdomain
```

# License

CC0-1.0 (Public Domain) \
See <https://creativecommons.org/publicdomain/zero/1.0/>.
