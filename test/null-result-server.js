#!/usr/bin/env node
// Fake language server for test/null-result.vim.  It answers every request with
// the result named in COPILOT_TEST_RESULT ("null" or "false"), which is what
// the real server sends for a completion it no longer has cached.
let buf = Buffer.alloc(0);
const RESULT = process.env.COPILOT_TEST_RESULT === 'false' ? false : null;

function send(msg) {
  const body = Buffer.from(JSON.stringify(msg), 'utf8');
  process.stdout.write('Content-Length: ' + body.length + '\r\n\r\n');
  process.stdout.write(body);
}

process.stdin.on('data', function (chunk) {
  buf = Buffer.concat([buf, chunk]);
  for (;;) {
    const sep = buf.indexOf('\r\n\r\n');
    if (sep === -1) return;
    const length = /Content-Length: *(\d+)/i.exec(buf.slice(0, sep).toString('ascii'));
    const total = sep + 4 + Number(length[1]);
    if (buf.length < total) return;
    const msg = JSON.parse(buf.slice(sep + 4, total).toString('utf8'));
    buf = buf.slice(total);
    handle(msg);
  }
});

function handle(msg) {
  if (msg.id === undefined || msg.id === null) {
    return;
  }
  if (msg.method === 'initialize') {
    send({jsonrpc: '2.0', id: msg.id, result: {
      capabilities: {
        textDocumentSync: {openClose: true, change: 2},
        inlineCompletionProvider: {},
        executeCommandProvider: {commands: ['github.copilot.didAcceptCompletionItem']}},
      serverInfo: {name: 'null-result-server', version: '0.0.1'}}});
  } else {
    send({jsonrpc: '2.0', id: msg.id, result: RESULT});
  }
}
