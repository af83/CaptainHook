# CaptainHook

CaptainHook is a quick, untested and ugly hook sniffer.

Elixir must be installed.

## Server

Launch with `mix do deps.get, server`. This server will persist on disk all
payload received via the http post verb.

## Simulate

A simulation will read the persisted payload, and post them onto the host.

``` shell
mix simulate -h host.com
```

``` shell
Command line options

• -h, --host      - the host to simulate on
• -d, --date      - as a path year, year/month/day/hour
• -p, --provider  - provider to test oprovider to test onn
• -s, --segment   - path of the url
• -f, --frequency - frequency in milliseconds
```
