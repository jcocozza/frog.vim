" global state
let s:frog_files = [] " from the user's perspective this behaves like a 1-indexed list
let s:prefix = "[🐸ribbit]"
if g:frog_use_args
    let s:frog_files = argv()
endif

" i is always out of bounds when list is len 0
function! s:OutofBounds(i)
    return a:i >= len(s:frog_files) || len(s:frog_files) == 0 || a:i < 0
endfunction

" swap two elements in the list
function! s:Swap(i, j)
    echo "bounds: " . a:i ", " . a:j
    if s:OutofBounds(a:i) || s:OutofBounds(a:j)
        return
    endif
    let l:v = s:frog_files[a:i]
    let s:frog_files[a:i] = s:frog_files[a:j]
    let s:frog_files[a:j] = l:v
endfunction

function! frog#AddFile()
    let abs_f = fnamemodify(expand('%:p'), ':p')
    let rel_f = fnamemodify(abs_f, ':.')
    let normalized_files = map(copy(s:frog_files), 'fnamemodify(v:val, ":p")')
    if index(normalized_files, abs_f) == -1
        echo s:prefix . " adding: " . rel_f
        call add(s:frog_files, rel_f)
    else
        echo s:prefix . " " . rel_f ." is already in list"
    endif
endfunction

function! frog#GoTo(idx)
    let userIdx = a:idx+1
    echo s:prefix . " going to " . userIdx
    if a:idx < len(s:frog_files)
        execute 'edit' s:frog_files[a:idx]
    else
        echo s:prefix . " no file found at " . userIdx
    endif
endfunction

function! frog#List()
    if len(s:frog_files) == 0
        echo s:prefix . " no frog files"
        return
    endif
    echo s:prefix
    for i in range(len(s:frog_files))
        echo (i+1) . ": " . s:frog_files[i]
    endfor
endfunction

function! s:PopulateScratcher()
    call setline(1, s:frog_files)
endfunction

" direction: up (-1); down(1)
function! s:Move(direction)
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
    call s:PopulateScratcher()
endfunction

function! s:SyncScratcher()
    let lines = getline(1, '$')
    let lines = filter(lines, 'v:val !=# ""')
    let s:frog_files = lines
endfunction

function! s:Scratcher()
    if len(s:frog_files) == 0
        echo s:prefix . " no frog files"
        return
    endif
    new
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nowrap
    setlocal noswapfile
    call PopulateScratcher()
    execute 'resize ' . len(s:frog_files)
    augroup FrogBuffer
        autocmd!
        autocmd TextChanged,TextChangedI <buffer> call s:SyncScratcher()
        nnoremap <buffer> <C-k> :call s:Move(-1)<CR>
        nnoremap <buffer> <C-j> :call s:Move(1)<CR>
        nnoremap <buffer> q :bd<CR>
        nnoremap <buffer> <ESC> :bd<CR>
        autocmd WinLeave <buffer> if &buftype == 'nofile' | bd! | endif
    augroup END
endfunction

let s:popup_id = -1
let s:selected_index = 0

function! s:PopupKeyHandler(id, key) abort
    if a:key ==# 'j' || a:key ==# "\<Down>"
        let s:selected_index = (s:selected_index + 1) % len(s:frog_files)
        call s:RedrawPopup()
    elseif a:key ==# 'k' || a:key ==# "\<Up>"
        let s:selected_index = (s:selected_index - 1 + len(s:frog_files)) % len(s:frog_files)
        call s:RedrawPopup()
    elseif a:key ==# 'J'
        call s:Swap(s:selected_index, s:selected_index+1)
        call s:RedrawPopup()
    elseif a:key ==# 'K'
        call s:Swap(s:selected_index, s:selected_index-1)
        call s:RedrawPopup()
    elseif a:key ==# 'd' || a:key ==# 'D'
        call remove(s:frog_files, s:selected_index)
        let s:selected_index = min([s:selected_index, len(s:frog_files)-1])
        call s:RedrawPopup()
    elseif a:key ==# "\<Esc>" || a:key ==# 'q'
        call popup_close(s:popup_id)
        let s:popup_id = -1
    elseif a:key ==# "\<CR>"
        call popup_close(s:popup_id)
        let s:popup_id = -1
        call frog#GoTo(s:selected_index)
    endif
    return v:true
endfunction

function! s:RedrawPopup() abort
    if s:popup_id != -1
        call popup_close(s:popup_id)
    endif
    let display = []
    for i in range(len(s:frog_files))
        let line = (i == s:selected_index ? '> ' : '  ') . (i+1) . ' ' .s:frog_files[i]
        call add(display, line)
    endfor
    let s:popup_id = popup_create(display, {
        \ 'minwidth': 30,
        \ 'minheight': 5,
        \ 'border': [],
        \ 'pos': 'center',
        \ 'filter': function('s:PopupKeyHandler'),
        \ 'zindex': 10,
        \ 'title': '[🐸frog.vim] - current hops'
        \ })
endfunction

function! frog#InteractiveList()
    if g:frog_use_popup
        call s:RedrawPopup()
    else
        call s:Scratcher()
    endif
endfunction
