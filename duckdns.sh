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

cmd_auth() { (
    if [ -z "${DUCKDNS_SH_SUBDOMAIN}" ]; then
        echo ""
        echo "You must provide a subdomain to authorize."
        echo ""
        printf "For reference, you already have tokens for"
        fn_list
        return 1
    fi

    if fn_check_env; then
        echo "'${DUCKDNS_SH_SUBDOMAIN}.duckdns.org' is already ready to update"
        echo "(to delete: 'rm ~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env')"
        exit 0
    fi

    fn_read_token
    echo "Created '~/.config/duckdns.sh/${DUCKDNS_SH_SUBDOMAIN}.env'"
); }

cmd_clear() { (
    fn_require_subdomain

    fn_duckdns_clear
); }

cmd_ip() { (
    fn_require_subdomain
    fn_require_dig

    echo dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    my_domain_ipv4="$(
        dig +short A "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    )"
    echo "${my_domain_ipv4:-(NONE)}"
    echo ""

    echo dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    my_domain_ipv6="$(
        dig +short AAAA "${DUCKDNS_SH_SUBDOMAIN}.duckdns.org"
    )"
    echo "${my_domain_ipv6:-(NONE)}"
    echo ""
); }

cmd_launcher_install() { (
    fn_require_subdomain
    fn_require_curl

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

cmd_launcher_uninstall() { (
    fn_require_subdomain

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

cmd_list() { (
    echo ""
    fn_list
); }

cmd_myip() { (
    fn_require_curl

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

cmd_run() { (
    fn_require_subdomain
    fn_require_env
    fn_require_curl
    fn_require_dig

    my_minutes=1
    my_wait="$((my_minutes * 60))"
    while true; do
        fn_update_ips
        echo ""
        echo ""
        echo "Waiting ${my_minutes}m to check '${DUCKDNS_SH_SUBDOMAIN}' again..."
        sleep "${my_wait}"
        echo ""
    done
); }

cmd_set() { (
    fn_require_subdomain
    fn_require_env
    fn_require_curl

    if [ -n "${DUCKDNS_SH_ARG_2}" ]; then
        fn_duckdns_update "${DUCKDNS_SH_ARG_1}" "${DUCKDNS_SH_ARG_2}"
        return 0
    fi

    case "${DUCKDNS_SH_ARG_1}" in
        *:[a-fA-F0-9]*)
            fn_duckdns_update '' "${DUCKDNS_SH_ARG_1}"
            ;;
        *[0-9].[0-9]*)
            fn_duckdns_update "${DUCKDNS_SH_ARG_1}" ''
            ;;
        *)
            echo "'${DUCKDNS_SH_ARG_1}' is not a valid IPv4 or IPv6 address"
            return 1
            ;;
    esac
) }

cmd_update() { (
    fn_require_subdomain
    fn_require_env
    fn_require_curl
    fn_require_dig

    fn_update_ips
); }

fn_check_env() { (
    if ! [ -e ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env" ]; then
        exit 1
    fi

    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
    if [ -z "${DUCKDNS_TOKEN-}" ]; then
        exit 1
    fi
); }

fn_duckdns_clear() { (
    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"

    echo curl -fsSL "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=****&clear=true"

    printf "Clearing IP address(es)... "

    curl --max-time 5.5 -fsSL "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&clear=true"
    # &verbose=true

    echo ""
); }

fn_duckdns_update() { (
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

    echo curl -fsSL "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=****${my_ipv4_param}${my_ipv6_param}"
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
            echo >&2 "at least one of ipv4 or ipv6 is required to update"
            return 1
        fi
    fi

    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
    curl --max-time 5.5 -fsSL "https://www.duckdns.org/update?domains=${DUCKDNS_SH_SUBDOMAIN}&token=${DUCKDNS_TOKEN}${my_ipv4_param}${my_ipv6_param}"

    # duckdns.org will respond with "OK", but we still need a newline
    echo ""
); }

fn_list() { (
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

fn_read_secret() { (
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

fn_read_token() { (
    mkdir -p ~/.config/duckdns.sh/

    echo "(the token will NOT BE SHOWN - just HIT ENTER after you paste it)"
    my_token="$(
        fn_read_secret 'Duck DNS Token> '
    )"

    echo "DUCKDNS_TOKEN=${my_token}" >> ~/.config/duckdns.sh/"${DUCKDNS_SH_SUBDOMAIN}.env"
); }

fn_require_curl() { (
    if ! command -v curl > /dev/null; then
        echo "command 'curl' not found: please install 'curl'"
        return 1
    fi
); }

fn_require_dig() { (
    if ! command -v dig > /dev/null; then
        echo "command 'dig' not found: please install 'dig' (part of 'dnsutils')"
        return 1
    fi
); }

fn_require_env() { (
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
); }

fn_require_subdomain() { (
    if [ -z "${DUCKDNS_SH_SUBDOMAIN}" ]; then
        printf "Missing <subdomain> argument. Try one of these in "
        fn_list
        return 1
    fi
); }

fn_update_ips() { (
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
        curl --max-time 5.5 -fsSL 'https://api.ipify.org?format=text'
    )"
    echo "IPv4 ${my_current_ipv4:-(NONE)}"
    echo ""

    echo curl -fsSL 'https://api64.ipify.org?format=text'
    my_current_ipv6="$(
        curl --max-time 5.5 -fsSL 'https://api64.ipify.org?format=text'
    )"
    if [ "${my_current_ipv4}" = "${my_current_ipv6}" ]; then
        my_current_ipv6=""
    fi
    echo "IPv6 ${my_current_ipv6:-(NONE)}"
    echo ""

    # if either ip changed to be empty, clear both
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ -z "${my_current_ipv4}" ]; then
            fn_duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi
    if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
        if [ -z "${my_current_ipv6}" ]; then
            fn_duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi

    # Note: at least one of the IPv4 or IPv6 *must* exist
    # (otherwise we wouldn't even be able to get a empty response)
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            fn_duckdns_update "${my_current_ipv4}" "${my_current_ipv6}"
        else
            fn_duckdns_update "${my_current_ipv4}" ""
        fi
    else
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            fn_duckdns_update "" "${my_current_ipv6}"
        else
            echo "No change detected."
        fi
    fi
); }

main() { (
    case "${DUCKDNS_SH_SUBCOMMAND}" in
        auth) cmd_auth ;;
        clear) cmd_clear ;;
        disable) cmd_launcher_uninstall ;;
        enable) cmd_launcher_install ;;
        help) fn_help ;;
        ip) cmd_ip ;;
        list) cmd_list ;;
        myip) cmd_myip ;;
        run) cmd_run ;;
        set) cmd_set ;;
        update) cmd_update ;;
        __noop__) ;;
        *)
            fn_help
            exit 1
            ;;
    esac
) }

fn_help() { (
    echo ""
    echo "USAGE"
    echo "    duckdns.sh <subcommand> [arguments...]"
    echo ""
    echo "SUBCOMMANDS"
    echo "    myip                         - show this device's ip(s)"
    echo "    ip <subdomain>               - show subdomain's ip(s)"
    echo ""
    echo "    list                         - show subdomains"
    echo "    auth <subdomain>             - add Duck DNS token"
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
