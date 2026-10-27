# pearl-proxy — agent notes

Release binaries: https://github.com/Forlives/pearl-proxy-release/releases/latest

## Non-interactive

```bash
pearl-proxy -coins [-json]
pearl-proxy -init -coin KAS -pool host:port -config config.json
pearl-proxy -check [-json] -config config.json   # exit 0/1
pearl-proxy -config config.json
pearl-proxy -version [-json]
```

## HTTP

- `GET /healthz` — no auth; `{ok, version, ports[{name,coin,pool_up}]}`
- `GET /api/stats|workers|sessions|pools|alerts` — Basic or `Authorization: Bearer <api_token>`
- `GET /api/workers.csv` / `/api/sessions.csv`
- `POST /api/reload` — Basic auth

## Dialects

`stratum` · `ethproxy` · `cryptonote`

Built-in coins: see `pearl-proxy -coins`. Custom profiles under `coins` in config.
