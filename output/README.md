<div align="center">

# mitmproxy

**An interactive TLS-capable intercepting HTTP proxy for penetration testers and software developers.**

![GitHub Release](https://img.shields.io/github/v/release/mitmproxy/mitmproxy?display_name=tag&color=%23a6a)
![GitHub License](https://img.shields.io/github/license/mitmproxy/mitmproxy)

</div>

## About

mitmproxy is a free and open source interactive HTTPS proxy. It lets you
intercept, inspect, modify and replay web traffic such as HTTP/1, HTTP/2,
HTTP/3, WebSockets, or any other SSL/TLS-protected protocols.

This package installs three commands:

- **`mitmproxy`**: an interactive console interface that allows traffic flows
  to be intercepted, inspected, modified and replayed.
- **`mitmdump`**: the command-line version of mitmproxy. Think tcpdump for
  HTTP.
- **`mitmweb`**: a web-based interface for mitmproxy, served on
  http://127.0.0.1:8081 by default.

**[Read the documentation](https://docs.mitmproxy.org/stable/)**

## Quick start

1. **Start the proxy** (it listens on port 8080 by default):

   ```sh
   mitmproxy          # console UI
   mitmweb            # web UI on http://127.0.0.1:8081
   mitmdump -w flows  # headless, save flows to a file
   ```

2. **Point your client at it**, for example:

   ```sh
   curl --proxy http://127.0.0.1:8080 http://example.com/
   ```

3. **Install the mitmproxy CA certificate** so HTTPS can be intercepted. The
   certificate is generated in `~/.mitmproxy/` on first run. With your client
   proxied, browse to [http://mitm.it](http://mitm.it) and follow the
   instructions for your platform.

## Proxy modes

Regular (the default), transparent, reverse, upstream, SOCKS5, WireGuard,
DNS and local capture modes are supported. Select one with `--mode`, for
example `mitmproxy --mode reverse:https://example.com` or
`mitmweb --mode wireguard`. See
[Proxy modes](https://docs.mitmproxy.org/stable/concepts/modes/).

## Addons

Traffic can be scripted with Python addons:

```sh
mitmdump -s ./my_addon.py
```

These are upstream's self-contained standalone builds, which bundle their own
Python interpreter and OpenSSL. Addon scripts can use the standard library and
everything mitmproxy itself ships with, but not Python packages installed on
the system. See [Addons](https://docs.mitmproxy.org/stable/addons/overview/)
and the [examples](https://github.com/mitmproxy/mitmproxy/tree/main/examples).

## Documentation

- [Documentation site](https://docs.mitmproxy.org/stable/)
- [Changelog](https://github.com/mitmproxy/mitmproxy/blob/main/CHANGELOG.md)
- [Upstream repository](https://github.com/mitmproxy/mitmproxy)
