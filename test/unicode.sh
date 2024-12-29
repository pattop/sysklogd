#!/bin/sh
# Currently only same as local.sh but with unicode messages
# From https://github.com/troglobit/sysklogd/issues/49
if [ -z "${srcdir}" ]; then
    srcdir=.
fi
. "${srcdir}/lib.sh"

MSG="öäüÖÄÜß€¢§"
MSG2="…‘’•"

setup_unicode()
{
    setup -8 -m0
}

check_log_message()
{
    message="${!#}"           # Get last argument
    [ $# -gt 1 ] && altsock="$1"

    logger "${altsock}" "$message"
    grep   "$message"   "$LOG"
}

run_step "Set up unicode capable syslogd" setup_unicode
run_step "Verify logger"                  check_log_message "$MSG"
run_step "Verify logger w/ alt. socket"   check_log_message "$ALTSOCK" "$MSG2"
