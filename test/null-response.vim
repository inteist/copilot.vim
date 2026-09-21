" Regression test for E716 on a response that carries no usable result.
"
" Neovim calls an LSP response handler with (nil, nil) when the server answers
" `result: null`, and -- because vim/lsp/rpc.lua passes
" `decoded.result ~= vim.NIL and decoded.result or nil` -- when it answers
" `result: false` as well.  The real server answers `false` from
" `workspace/executeCommand` whenever the completion uuid has left its cache,
" which is how accepting a suggestion used to throw
"
"   E716: Key not present in Dictionary: "error"
"
" out of a vim.schedule callback.  Both responses must resolve the request.
"
" Run: nvim --clean --headless -u test/null-response.vim
" Exits non-zero if anything fails.
set nocompatible
let s:root = expand('<sfile>:h:h')
execute 'set rtp^=' . fnameescape(s:root)
let g:copilot_command = [s:root . '/test/stub-server.py']
let g:copilot_no_startup_warnings = 1
runtime plugin/copilot.vim

let s:failures = 0

function! s:Check(name, expected, actual) abort
  if a:expected ==# a:actual
    echo 'ok   ' . a:name
  else
    let s:failures += 1
    echo 'FAIL ' . a:name
    echo '     expected: ' . string(a:expected)
    echo '     actual:   ' . string(a:actual)
  endif
endfunction

" One round trip against the stub.  Reports the outcome as a string so that a
" thrown E716 shows up as a failed comparison rather than as a stack trace.
function! s:Roundtrip(method) abort
  let outcome = ['']
  try
    call copilot#Request(a:method, {},
          \ { result -> extend(outcome, ['resolved ' . string(result)], 0) },
          \ { error -> extend(outcome, ['rejected ' . string(error)], 0) })
    for _ in range(500)
      if !empty(outcome[0])
        break
      endif
      sleep 10m
    endfor
  catch
    " The callback throws from inside vim.schedule() rather than from here, so
    " this only catches a synchronous failure; the asynchronous one shows up as
    " a timeout.
    return 'threw ' . v:exception
  endtry
  return empty(outcome[0]) ? 'timeout' : outcome[0]
endfunction

function! s:Main() abort
  " vim.lsp.start() attaches to the current buffer, which is not loaded yet
  " while this file is still being sourced.
  enew
  call s:Check('result: null resolves', 'resolved v:null', s:Roundtrip('test/nullResult'))
  call s:Check('result: false resolves', 'resolved v:null', s:Roundtrip('test/falseResult'))
  if s:failures
    echo s:failures . ' failure(s)'
    cquit
  endif
  echo 'all tests passed'
  qall!
endfunction

autocmd VimEnter * call s:Main()
