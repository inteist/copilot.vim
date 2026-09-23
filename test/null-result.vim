" A response whose result is JSON null -- or false, which Neovim's LSP client
" also hands to Lua as nil -- must resolve the request rather than be mistaken
" for an error.  github.copilot.didAcceptCompletionItem answers exactly that
" for a completion the server no longer has cached, and the Neovim transport
" used to drop the `result` key on the floor and then read `response.error`.
"
" Run: nvim --clean --headless -u test/null-result.vim </dev/null
" Exits non-zero if anything fails.  Run it under a timeout: the bug this
" guards against raises the error from a vim.schedule callback, and Neovim
" blocks on the prompt for it rather than carrying on to the checks.
set nocompatible
let s:root = expand('<sfile>:h:h')
execute 'set rtp^=' . fnameescape(s:root)

if !has('nvim')
  echo 'skip null-result.vim (Neovim only)'
  qall!
endif
if !executable('node')
  echo 'skip null-result.vim (node not found)'
  qall!
endif

let g:copilot_command = ['node', s:root . '/test/null-result-server.js']
let g:copilot_npx = v:false
let $COPILOT_TEST_RESULT = 'null'
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

" Wait for `Cond()` for up to three seconds, so the test does not race the
" server starting up.
function! s:Wait(Cond) abort
  for i in range(300)
    if call(a:Cond, [])
      return 1
    endif
    sleep 10m
  endfor
  return call(a:Cond, [])
endfunction

" The client starts on demand and queues the request until the server has
" initialised, so there is nothing to wait for before sending one.
function! s:Roundtrip(name) abort
  let request = copilot#Request('workspace/executeCommand', {
        \ 'command': 'github.copilot.didAcceptCompletionItem',
        \ 'arguments': ['00000000-0000-0000-0000-000000000000']})
  call s:Wait({ -> get(request, 'status', '') !=# 'running' })
  call s:Check(a:name . ': request resolves', 'success', get(request, 'status', ''))
  call s:Check(a:name . ': result is null', v:null, get(request, 'result', 'missing'))
endfunction

" Neovim will not start an LSP client while it is still starting up, so the
" run waits for VimEnter.
function! s:Main(...) abort
  call s:Roundtrip('null result')

  " A false result reaches Lua as nil as well, so it takes the same path.  The
  " server reads the environment as it is spawned, so set it before restarting.
  let $COPILOT_TEST_RESULT = 'false'
  silent Copilot restart
  call s:Roundtrip('false result')

  if s:failures
    echo s:failures . ' FAILURE(S)'
    cquit
  else
    echo 'all tests passed'
    qall!
  endif
endfunction

autocmd VimEnter * call timer_start(0, function('s:Main'))
