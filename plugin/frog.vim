let g:frog_files = []
let g:use_args = 1
let g:use_popup = 1
let g:prefix = "[🐸ribbit]"

if g:use_args
    let g:frog_files = argv()
endif

" i is always out of bounds when list is len 0
function! OutofBounds(i)
    return a:i >= len(g:frog_files) || len(g:frog_files) == 0 || a:i < 0
endfunction

" swap two elements in the list
function! s:Swap(i, j)
    echo "bounds: " . a:i ", " . a:j
    if OutofBounds(a:i) || OutofBounds(a:j)
        return
    endif
    let l:v = g:frog_files[a:i]
    let g:frog_files[a:i] = g:frog_files[a:j]
    let g:frog_files[a:j] = l:v
endfunction

function! AddFile()
    let f = expand("%:p")
    if index(g:frog_files, f) == -1
        echo g:prefix . " adding: " . f
        call add(g:frog_files, f)
    else
        echo g:prefix . " already in list"
    endif
endfunction

function! GoTo(idx)
    let userIdx = a:idx+1
    echo g:prefix . " going to " . userIdx
    if a:idx < len(g:frog_files)
        execute 'edit' g:frog_files[a:idx]
    else
        echo g:prefix . " no file found at " . userIdx
    endif
endfunction

function! List()
    if len(g:frog_files) == 0
        echo g:prefix . " no frog files"
        return
    endif
    echo g:prefix
    let i = 1
    for f in g:frog_files
        echo i . ": " . f
        let i = i + 1
    endfor
endfunction

function! PopulateScratcher()
    call setline(1, g:frog_files)
endfunction

" direction: up (-1); down(1)
function! Move(direction)
    let lnum = line('.')
    if lnum == 1 && a:direction == -1
        return
    endif
    if lnum == line('$') && a:direction == 1
        return
    endif
    let lnum = lnum-1
    let targetline = lnum + a:direction
    call s:Swap(lnum, targetline)
    call PopulateScratcher()
endfunction

function! Down()
    let lnum = line('.')
    if lnum == 0
        return
    endif
endfunction

function! SyncScratcher()
    let lines = getline(1, '$')
    let lines = filter(lines, 'v:val !=# ""')
    let g:frog_files = lines
endfunction

function! Scratcher()
    if len(g:frog_files) == 0
        echo g:prefix . " no frog files"
        return
    endif

    new
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nowrap
    setlocal noswapfile
    call PopulateScratcher()

    execute 'resize ' . len(g:frog_files)

    augroup FrogBuffer
        autocmd!
        autocmd TextChanged,TextChangedI <buffer> call SyncScratcher()
        nnoremap <buffer> <C-k> :call Move(-1)<CR>
        nnoremap <buffer> <C-j> :call Move(1)<CR>
        nnoremap <buffer> q :bd<CR>
        nnoremap <buffer> <ESC> :bd<CR>
        autocmd WinLeave <buffer> if &buftype == 'nofile' | bd! | endif
    augroup END
endfunction



let s:popup_id = -1
let s:selected_index = 0

function! s:PopupKeyHandler(id, key) abort
    echom 'Pressed: "' . a:key . '" (ASCII: ' . char2nr(a:key) . ')'

  if a:key ==# 'j' || a:key ==# "\<Down>"
    let s:selected_index = (s:selected_index + 1) % len(g:frog_files)
    call s:RedrawPopup()
  elseif a:key ==# 'k' || a:key ==# "\<Up>"
    let s:selected_index = (s:selected_index - 1 + len(g:frog_files)) % len(g:frog_files)
    call s:RedrawPopup()
  elseif a:key ==# 'J'
    call s:Swap(s:selected_index, s:selected_index+1)
    call s:RedrawPopup()
  elseif a:key ==# 'K'
    call s:Swap(s:selected_index, s:selected_index-1)
    call s:RedrawPopup()
  elseif a:key ==# 'd' || a:key ==# 'D'
    call remove(g:frog_files, s:selected_index)
    let s:selected_index = min([s:selected_index, len(g:frog_files)-1])
    call s:RedrawPopup()
  elseif a:key ==# "\<Esc>" || a:key ==# 'q'
    call popup_close(s:popup_id)
    let s:popup_id = -1
  elseif a:key ==# "\<CR>"
    call popup_close(s:popup_id)
    let s:popup_id = -1
    call GoTo(s:selected_index)
  endif
  return v:true
endfunction

function! s:RedrawPopup() abort
  if s:popup_id != -1
    call popup_close(s:popup_id)
  endif

  " Highlight selected item
  let display = []
  for i in range(len(g:frog_files))
    let line = (i == s:selected_index ? '> ' : '  ') . (i+1) . ' ' .g:frog_files[i]
    call add(display, line)
  endfor

  let s:popup_id = popup_create(display, {
        \ 'minwidth': 30,
        \ 'minheight': 5,
        \ 'border': [],
        \ 'pos': 'center',
        \ 'filter': function('s:PopupKeyHandler'),
        \ 'zindex': 10,
        \ 'title': 'frog.vim - current hops'
        \ })
endfunction



function! Popup()
    call s:RedrawPopup()
endfunction

nnoremap <C-a> :call AddFile()<CR>
nnoremap <C-p> :call List()<CR>
if g:use_popup
    nnoremap <C-l> :call Popup()<CR>
else
    nnoremap <C-l> :call Scratcher()<CR>
endif

nnoremap <Space>1 :call GoTo(0)<CR>
nnoremap <Space>2 :call GoTo(1)<CR>
nnoremap <Space>3 :call GoTo(2)<CR>
nnoremap <Space>4 :call GoTo(3)<CR>
