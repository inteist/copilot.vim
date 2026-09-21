#!/usr/bin/env python3
"""Stub language server for test/null-response.vim.

Answers `initialize` with empty capabilities, `test/nullResult` with JSON null
and `test/falseResult` with false -- the two responses Neovim hands a copilot
response handler as (nil, nil).  The real server sends `false` from
`workspace/executeCommand` whenever the completion uuid has left its cache.
"""
import json
import sys

RESULTS = {
    'test/nullResult': None,
    'test/falseResult': False,
}


def read_message():
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        line = line.strip()
        if not line:
            break
        key, _, value = line.decode().partition(':')
        headers[key.strip().lower()] = value.strip()
    length = int(headers.get('content-length', 0))
    return json.loads(sys.stdin.buffer.read(length).decode())


def send(obj):
    body = json.dumps(obj).encode()
    sys.stdout.buffer.write(b'Content-Length: %d\r\n\r\n' % len(body))
    sys.stdout.buffer.write(body)
    sys.stdout.buffer.flush()


while True:
    message = read_message()
    if message is None:
        break
    if 'id' not in message:
        continue
    method = message.get('method', '')
    if method == 'initialize':
        result = {'capabilities': {},
                  'serverInfo': {'name': 'stub', 'version': '0.0.1'}}
    else:
        result = RESULTS.get(method, {})
    send({'jsonrpc': '2.0', 'id': message['id'], 'result': result})
