# gemini_server

A simple gemini server written to learn some Gleam.

## Getting started (local dev)

1. Setup self-signed ssl certs

```bash
openssl req -x509 -nodes -newkey rsa:4096 -keyout server.key -out server.crt -sha256 -days 365
```

2. Run server

```
gleam run
```

3. Test server with little python script

Currently this script just connects with TLS and then
requests `gemini://localhost/` and prints the result.

I'll develop this test script as I develop the server itself though to better test out the protocol. (Once the server is more fully fledged I'll try some official gemini clients)

```
cd server-test
cp ../server.crt ./
python test.py
```
