" Tests for the fork's <Tab> behaviour: one word per press, the rest of the
" suggestion on a quick second press.
"
" Run: nvim --clean --headless -u test/double-tab.vim
" Exits non-zero if anything fails.
set nocompatible
set noexpandtab
let s:root = expand('<sfile>:h:h')
execute 'set rtp^=' . fnameescape(s:root)
runtime plugin/copilot.vim

" Force the autoload file to load, then neuter everything that talks to the
" language server so the tests need no running Copilot.
silent! call copilot#GetDisplayedSuggestion()
function! copilot#Request(method, params, ...) abort
  return {}
endfunction
function! copilot#Notify(method, params, ...) abort
  return {}
endfunction
function! copilot#Suggest() abort
  return ''
endfunction
function! copilot#Enabled() abort
  return 1
endfunction

let s:failures = 0

" Called from insert mode at the point the suggestion would be displayed.
function! Setup() abort
  let start = col('.') - 1
  let b:_copilot = {
        \ 'suggestions': [{
        \   'insertText': g:test_text,
        \   'range': {'start': {'line': line('.') - 1, 'character': start},
        \             'end':   {'line': line('.') - 1, 'character': start + g:test_overlap}}}],
        \ 'choice': 0}
  return ''
endfunction

function! Pause() abort
  execute 'sleep' g:test_pause . 'm'
  return ''
endfunction

function! Wipe() abort
  unlet! b:_copilot
  return ''
endfunction

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

" name, buffer line, key that enters insert at the right spot ('A', or a count
" plus '|i'), suggestion text, how many existing chars the suggestion range
" covers, keys to feed, expected buffer.
function! s:Run(name, line, enter, text, overlap, keys, expected) abort
  enew!
  setlocal noexpandtab buftype=nofile
  call setline(1, a:line)
  call cursor(1, 1)
  let g:test_text = a:text
  let g:test_overlap = a:overlap
  call feedkeys(a:enter . "\<C-R>\<C-R>=Setup()\<CR>" . a:keys . "\<Esc>", 'mtx')
  call s:Check(a:name, a:expected, getline(1, '$'))
endfunction

let g:copilot_double_tab_timeout = 300

call s:Run('single tab accepts one word',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>", ['let x = foo'])

call s:Run('double tab accepts the whole suggestion',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>\<Tab>", ['let x = foo bar baz'])

call s:Run('double tab survives the state being refreshed in between',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>\<C-R>\<C-R>=Wipe()\<CR>\<Tab>", ['let x = foo bar baz'])

call s:Run('triple tab does not duplicate text',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>\<Tab>\<Tab>", ["let x = foo bar baz\t"])

call s:Run('double tab completes a multi-line suggestion',
      \ 'if x:', 'A', "\n\tfoo bar\n\tbaz", 0,
      \ "\<Tab>\<Tab>", ['if x:', "\tfoo bar", "\tbaz"])

call s:Run('double tab deletes overlapped trailing text',
      \ 'foo()', '5|i', 'bar)', 1,
      \ "\<Tab>\<Tab>", ['foo(bar)'])

call s:Run('single tab keeps overlapped trailing text',
      \ 'foo()', '5|i', 'bar)', 1,
      \ "\<Tab>", ['foo(bar)'])

call s:Run('typing between the tabs closes the window',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>z\<Tab>", ["let x = fooz\t"])

" Window closed: the second tab is just another word accept.
let g:copilot_double_tab_timeout = 0
call s:Run('slow second tab accepts a second word',
      \ 'let x = ', 'A', 'foo bar baz', 0,
      \ "\<Tab>\<Tab>", ['let x = foo bar'])
let g:copilot_double_tab_timeout = 300

" Same thing with real elapsed time rather than a zeroed timeout.
function! s:RunTimed(name, pause, expected) abort
  enew!
  setlocal noexpandtab buftype=nofile
  call setline(1, 'let x = ')
  call cursor(1, 1)
  let g:test_text = 'foo bar baz'
  let g:test_overlap = 0
  let g:test_pause = a:pause
  call feedkeys("A\<C-R>\<C-R>=Setup()\<CR>\<Tab>\<C-R>\<C-R>=Pause()\<CR>\<Tab>\<Esc>", 'mtx')
  call s:Check(a:name, a:expected, getline(1, '$'))
endfunction

let g:copilot_double_tab_timeout = 300
call s:RunTimed('second tab inside the real window accepts the rest', 50,
      \ ['let x = foo bar baz'])
let g:copilot_double_tab_timeout = 100
call s:RunTimed('second tab past the real window accepts a word', 250,
      \ ['let x = foo bar'])
let g:copilot_double_tab_timeout = 300

" No suggestion at all: <Tab> must fall through to a literal tab.
enew!
setlocal noexpandtab buftype=nofile
call setline(1, 'x')
call cursor(1, 1)
call feedkeys("A\<Tab>\<Esc>", 'mtx')
call s:Check('tab without a suggestion inserts a tab', ["x\t"], getline(1, '$'))

if s:failures
  echo s:failures . ' FAILURE(S)'
  cquit
else
  echo 'all tests passed'
  qall!
endif
