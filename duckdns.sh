#!/bin/sh

set -e
set -u

# ipify API docs: https://ipify.org
# duckdns API docs: https://duckdns.org/spec.jsp

DUCKDNS_SH_COMMAND=${DUCKDNS_SH_COMMAND:-${0:-duckdns.sh}}
DUCKDNS_SH_SUBCOMMAND="${DUCKDNS_SH_SUBCOMMAND:-${1-}}"
DUCKDNS_SH_SUBDOMAIN="${DUCKDNS_SH_SUBDOMAIN:-${2-}}"
DUCKDNS_SH_ARG_1="${DUCKDNS_SH_ARG_1:-${3-}}"
DUCKDNS_SH_ARG_2="${DUCKDNS_SH_ARG_2:-${4-}}"

_init() { (
    _check_subdomain

    if env_check; then
        echo "'${DUCKDNS_SH_SUBDOMAIN}.duckdns.org' is already ready to update"
        echo "(to delete: 'rm ~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env')"
        exit 0
    fi

    read_token
    echo "Created '~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env'"
); }

_check_subdomain() { (
    if [ -z "${DUCKDNS_SH_SUBDOMAIN}" ]; then
        printf "Missing <subdomain> argument. Try one of these in "
        _list
        return 1
    fi
); }

env_check() { (
    if [ -z "${DUCKDNS_TOKEN-}" ]; then
        if ! [ -e ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env" ]; then
            exit 1
        fi

        # shellcheck disable=SC1090
        . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
        if [ -z "${DUCKDNS_TOKEN-}" ]; then
            exit 1
        fi
    fi
); }

dep_check() { (
    if [ -z "${DUCKDNS_TOKEN-}" ]; then
        if ! [ -e ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env" ]; then
            echo "Missing '~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env'"
            exit 1
        fi

        # shellcheck disable=SC1090
        . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
        if [ -z "${DUCKDNS_TOKEN-}" ]; then
            echo "Missing 'DUCKDNS_TOKEN=<uuid>' from '~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env'"
            exit 1
        fi
    fi

    if ! command -v dig > /dev/null; then
        echo "command 'dig' not found: please install 'dig' (part of 'dnsutils')"
        return 1
    fi

    if ! command -v curl > /dev/null; then
        echo "command 'curl' not found: please install 'curl'"
        return 1
    fi
); }

_update() { (
    _check_subdomain
    dep_check

    _update_ips
); }

_show_ips() { (
    _check_subdomain

    echo dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"

    echo ""

    echo dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
); }

_my_ips() { (
    echo curl -fsSL 'https://api.ipify.org?format=text'
    my_current_ipv4="$(
        curl --max-time 5.5 -fsSL 'https://api.ipify.org?format=text'
    )"
    echo "${my_current_ipv4:-(NONE)}"

    echo ""

    echo curl -fsSL 'https://api64.ipify.org?format=text'
    my_current_ipv6="$(
        curl --max-time 5.5 -fsSL 'https://api64.ipify.org?format=text'
    )"
    if [ "${my_current_ipv4}" = "${my_current_ipv6}" ]; then
        my_current_ipv6=""
    fi
    echo "${my_current_ipv6:-(NONE)}"
); }

_update_ips() { (
    echo dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    my_domain_ipv4="$(
        dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    )"
    echo "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org A ${my_domain_ipv4:-(NONE)}"
    echo ""

    echo dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    my_domain_ipv6="$(
        dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    )"
    echo "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org AAAA ${my_domain_ipv6:-(NONE)}"
    echo ""

    echo curl -fsSL 'https://api.ipify.org?format=text'
    my_current_ipv4="$(
        curl -fsSL 'https://api.ipify.org?format=text'
    )"
    echo "IPv4 ${my_current_ipv4:-(NONE)}"
    echo ""

    echo curl -fsSL 'https://api64.ipify.org?format=text'
    my_current_ipv6="$(
        curl -fsSL 'https://api64.ipify.org?format=text'
    )"
    if [ "${my_current_ipv4}" = "${my_current_ipv6}" ]; then
        my_current_ipv6=""
    fi
    echo "IPv6 ${my_current_ipv6:-(NONE)}"
    echo ""

    # if either ip changed to be empty, clear both
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ -z "${my_current_ipv4}" ]; then
            duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi
    if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
        if [ -z "${my_current_ipv6}" ]; then
            duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi

    # Note: at least one of the IPv4 or IPv6 *must* exist
    # (otherwise we wouldn't even be able to get a empty response)
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            duckdns_update "${my_current_ipv4}" "${my_current_ipv6}"
        else
            duckdns_update "${my_current_ipv4}" ""
        fi
    else
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            duckdns_update "" "${my_current_ipv6}"
        else
            echo "No change detected."
        fi
    fi
); }

read_token() { (
    mkdir -p ~/.config/duckdns.sh/

    echo "(the token will NOT BE SHOWN - just HIT ENTER after you paste it)"
    my_token="$(
        read_secret 'Duck DNS Token> '
    )"

    echo "DUCKDNS_TOKEN=${my_token}" >> ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
); }

read_secret() { (
    my_prompt="${1}"
    # always read from the tty even when redirected:
    # || exit only needed for bash
    exec < /dev/tty || exit

    # save current tty settings:
    tty_settings="$(stty -g)" || exit

    # schedule restore of the settings on exit of that subshell
    # or on receiving SIGINT or SIGTERM:
    trap 'stty "$tty_settings"' EXIT INT TERM

    # disable terminal local echo
    stty -echo || exit

    # prompt on tty
    printf "%s" "${my_prompt}" > /dev/tty

    # read password as one line, record exit status
    IFS= read -r my_password
    ret=$?

    # display a newline to visually acknowledge the entered password
    echo > /dev/tty

    # return the password for $REPLY
    printf '%s\n' "$my_password"
    exit "$ret"
); }

duckdns_clear() { (
    _check_subdomain

    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"

    printf "Clearing IP address(es)... "

    curl "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&clear=true"
    # &verbose=true

    echo ""
); }

duckdns_update() { (
    my_ipv4="${1}"
    my_ipv6="${2-}"

    my_ipv4_param=""
    if [ -n "${my_ipv4}" ]; then
        my_ipv4_param="&ip=${my_ipv4}"
    fi

    my_ipv6_param=""
    if [ -n "${my_ipv6}" ]; then
        my_ipv6_param="&ipv6=${my_ipv6}"
    fi

    echo curl "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=****${my_ipv4_param}${my_ipv6_param}"
    # &verbose=true

    if [ -n "${my_ipv6_param}" ]; then
        if [ -n "${my_ipv4_param}" ]; then
            printf "Updating IPv4 (%s) and IPv6 (%s) ... " "${my_ipv4}" "${my_ipv6}"
        else
            printf "Updating IPv6 (%s)... " "${my_ipv6}"
        fi
    else
        if [ -n "${my_ipv4_param}" ]; then
            printf "Updating IPv4 (%s)... " "${my_ipv4}"
        else
            echo >&2 "duckdns_update must receive at least one of ipv4 or ipv6"
            return 1
        fi
    fi

    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
    curl "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=${DUCKDNS_TOKEN}${my_ipv4_param}${my_ipv6_param}"

    # duckdns.org will respond with "OK", but we still need a newline
    echo ""
); }

_list() { (
    # shellcheck disable=SC2088
    echo '~/.config/duckdns.sh/:'

    if ! [ -e ~/.config/duckdns.sh ]; then
        echo "    (directory does not exist)"
    fi

    for my_domainenv in ~/.config/duckdns.sh/*; do
        my_domainenv="$(basename "$my_domainenv" ".env")"

        # handle special case of 0 matches (* becomes literal)
        if [ '*' = "${my_domainenv}" ]; then
            echo "    (no subdomains have been configured)"
            continue
        fi

        echo "    ${my_domainenv}"
    done

    echo ""
); }

_run() { (
    _check_subdomain
    dep_check

    my_minutes=1
    my_wait="$((my_minutes * 60))"
    while true; do
        _update_ips
        echo ""
        echo ""
        echo "Waiting ${my_minutes}m to check '${DUCKDNS_SH_SUBDOMAIN}' again..."
        sleep "${my_wait}"
        echo ""
    done
); }

_set() { (
    _check_subdomain

    if [ -n "${DUCKDNS_SH_ARG_2}" ]; then
        duckdns_update "${DUCKDNS_SH_ARG_1}" "${DUCKDNS_SH_ARG_2}"
        return 0
    fi

    case "${DUCKDNS_SH_ARG_1}" in
        *:[a-fA-F0-9]*)
            duckdns_update '' "${DUCKDNS_SH_ARG_1}"
            ;;
        *[0-9].[0-9]*)
            duckdns_update "${DUCKDNS_SH_ARG_1}" ''
            ;;
        *)
            echo "'${DUCKDNS_SH_ARG_1}' is not a valid IPv4 or IPv6 address"
            return 1
            ;;
    esac
) }

launcher_install() { (
    if ! command -v serviceman > /dev/null; then
        curl --max-time 5.5 -fsSL https://webinstall.dev/serviceman | sh
        # shellcheck disable=SC1090
        . ~/.config/envman/PATH.env
    fi

    # macOS
    if command -v launchctl > /dev/null; then
        serviceman add --user --name sh.duckdns."${DUCKDNS_SH_SUBDOMAIN}" -- \
            "${DUCKDNS_SH_COMMAND}" run "${DUCKDNS_SH_SUBDOMAIN}"
        exit 0
    fi

    # Linux (Ubuntu, Debian, etc)
    if command -v systemctl > /dev/null; then
        echo ""
        echo Running command: sudo env PATH="\$PATH" \
            serviceman add --system --path="\$PATH" --username "$(whoami)" --name "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh" -- \
            "${DUCKDNS_SH_COMMAND}" run "${DUCKDNS_SH_SUBDOMAIN}"
        echo ""
        sudo env PATH="$PATH" \
            serviceman add --system --path="$PATH" --username "$(whoami)" --name "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh" -- \
            "${DUCKDNS_SH_COMMAND}" run "${DUCKDNS_SH_SUBDOMAIN}"

        echo ""
        echo Running command: sudo systemctl restart systemd-journald
        echo ""
        sudo systemctl restart systemd-journald
        exit 0
    fi

    echo "'launchctl' (macOS) and 'systemd' (Linux) are the only currently supported launchers"
    exit 1
); }

launcher_uninstall() { (
    # macOS
    if command -v launchctl > /dev/null; then
        launchctl unload -w sh.duckdns."${DUCKDNS_SH_SUBDOMAIN}"

        echo "Disabled login launcher: sh.duckdns.${DUCKDNS_SH_SUBDOMAIN}"
        exit 0
    fi

    # Linux (Ubuntu, Debian, etc)
    if command -v systemctl > /dev/null; then
        echo Running command: sudo systemctl stop "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh"
        sudo systemctl stop "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh"

        echo Running command: sudo systemctl disable "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh"
        sudo systemctl disable "${DUCKDNS_SH_SUBDOMAIN}.duckdns-sh"

        echo "Disabled system launcher."
        exit 0
    fi

    echo "'launchctl' (macOS) and 'systemd' (Linux) are the only currently supported launchers"
    exit 1
); }

main() { (
    if [ "noop" = "${DUCKDNS_SH_NOOP-}" ]; then
        return 0
    fi

    case "${DUCKDNS_SH_SUBCOMMAND}" in
        clear) duckdns_clear ;;
        enable) launcher_install ;;
        disable) launcher_uninstall ;;
        help) _help ;;
        init) _init ;;
        ip) _show_ips ;;
        list)
            echo ""
            _list
            ;;
        myip) _my_ips ;;
        run) _run ;;
        set) _set ;;
        update) _update ;;
        *)
            _help
            exit 1
            ;;
    esac
) }

_help() { (
    echo ""
    echo "USAGE"
    echo "    duckdns.sh <subcommand> [arguments...]"
    echo ""
    echo "SUBCOMMANDS"
    echo "    myip                         - show this device's ip(s)"
    echo "    ip <subdomain>               - show subdomain's ip(s)"
    echo ""
    echo "    list                         - show subdomains"
    echo "    init <subdomain>             - add Duck DNS token"
    echo "    update <subdomain>           - update subdomain to device ip"
    echo "    set <subdomain> <ip> [ipv6]  - set ipv4 and/or ipv6 explicitly"
    echo "    clear <subdomain>            - unset ip(s)"
    echo "    run <subdomain>              - check ip and update every 5m"
    echo "    enable <subdomain>           - enable on boot (Linux) or login (macOS)"
    echo "    disable <subdomain>          - disable on boot or login"
    echo ""
    echo "    help                         - show this menu"
    echo ""
); }

main
