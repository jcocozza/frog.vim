" global state
"
" this is a list of dictonaries
" each dictionary looks like:
" {
"  'rel': '<relative path>'
"  'abs': '<absolute path>'
"  'line': <row num>
"  'col': <col num>
" }
"
" implict in this is the ordering of the file bindings
" e.g. idx 0 => <leader>1, idx 1 => <leader>2
" reordering the list reorders where the bindings point to
"
" the user always interacts with this list as a 1 indexed list
" e.g. Whenever the user asks for element 1, that is the 0th element of the
" list
"
" All exposed functions assume a 1-based indexing system
" they need adjust to the 0 system from there.
" Moreover, functions that output indicies need to adjust for this as well
let s:frog_files = []

" purely asthetic
let s:prefix = "[🐸ribbit]"

if g:frog_use_args
    for f in argv()
        let ff = { 'col': 1, 'line': 1, 'rel': f, 'abs': fnamemodify(f, ":p") }
        call add(s:frog_files, ff)
    endfor
endif

" check if i is a valid index for s:frog_files
"
" if the list is empty then any index is invalid
function! s:OutofBounds(i)
    return a:i >= len(s:frog_files) || len(s:frog_files) == 0
endfunction

" swap the i-th and j-th elements in s:frog_files
function! s:Swap(i, j)
    if s:OutofBounds(a:i) || s:OutofBounds(a:j)
        return
    endif
    let l:v = s:frog_files[a:i]
    let s:frog_files[a:i] = s:frog_files[a:j]
    let s:frog_files[a:j] = l:v
endfunction

" return the idx of the passed path in s:frog_files
" otherwise return -1
function! s:Idx(abs_path)
    for i in range(len(s:frog_files))
        if a:abs_path == s:frog_files[i]['abs']
            return i
        endif
    endfor
    return -1
endfunction

" print the list - debugging
function! frog#Print()
    echomsg s:prefix
    for i in range(len(s:frog_files))
        echomsg (i+1) . " " s:frog_files[i]['rel'] . " " . s:frog_files[i]['line'] . " " . s:frog_files[i]['col']
    endfor
endfunction

" add the current file to the list
" at the current cursor location
"
" if file already exists, overwrite locations
function! frog#AddFile()
    let c = col(".")
    let l = line(".")
    let abs_f = fnamemodify(expand('%:p'), ':p')
    let rel_f = fnamemodify(abs_f, ':.')

    for i in range(len(s:frog_files))
        if abs_f == s:frog_files[i]['abs']
            let s:frog_files[i]['line'] = l
            let s:frog_files[i]['col'] = c
            return
        endif
    endfor

    let ff = { 'col': c, 'line': l, 'rel': rel_f, 'abs': abs_f }
    call add(s:frog_files, ff)
endfunction

" if verbose warn the user if not in list, or tell them what marker was
" updated to
function! frog#Update(verbose)
    let c = col(".")
    let l = line(".")
    let abs_f = fnamemodify(expand('%:p'), ':p')

    let idx = s:Idx(abs_f)

    if idx == -1
        if a:verbose
            echoerr abs_f . " not in frog list"
        endif
        return
    endif

    if a:verbose
        echomsg "updated marker to line: " . l  . " col: " . c
    endif
    let s:frog_files[idx]['line'] = l
    let s:frog_files[idx]['col'] = c
endfunction

" remove the idx-1 element from s:frog_files
function! frog#Remove(idx)
    if a:idx > 0 && a:idx <= len(s:frog_files)
        call remove(s:frog_files, a:idx-1)
    endif
endfunction

" open file corresponding to idx-1 in s:frog_files
function! frog#GoTo(idx)
    let adj_idx = a:idx - 1
    if s:OutofBounds(adj_idx)
        echomsg s:prefix . " no file found at " . a:idx
        return
    endif
    execute 'edit' s:frog_files[adj_idx]['rel']
    call cursor(s:frog_files[adj_idx]['line'], s:frog_files[adj_idx]['col'])
endfunction

" return a list of strings
"
" these are to be rendered (line by line)
" to a buffer
"
" curr is the selected idx
"
" if curr == -1, don't include prefix >
function! s:LineList(curr)
    let display = []
    for i in range(len(s:frog_files))
        let line = ""
        if a:curr == -1
            let line = (i+1) . ' ' . s:frog_files[i]['rel'] . ':' . s:frog_files[i]['col'] . ':' . s:frog_files[i]['line']
        else
            let line = (i == a:curr ? '> ' : '  ') . (i+1) . ' ' . s:frog_files[i]['rel'] . ':' . s:frog_files[i]['col'] . ':' . s:frog_files[i]['line']
        endif
        call add(display, line)
    endfor
    return display
endfunction

function! s:RedrawBuffer()
    setlocal modifiable
    let display = s:LineList(-1)
    echomsg display
    call setline(1, display)
    redraw
    setlocal nomodifiable
endfunction

function! s:RedrawBuffer()
    setlocal modifiable
    let display = s:LineList(-1)
    call deletebufline('%', 1, '$')
    if !empty(display)
        call setline(1, display)
    endif
    let lnum = min([line('.'), len(display)])
    call cursor(lnum, 1)
    setlocal nomodifiable
endfunction

function! s:RemoveFromBuffer()
    call frog#Remove(line("."))
    call s:RedrawBuffer()
endfunction

function! s:SwapUp()
    call s:Swap(line("."), line(".")-1)
    call s:RedrawBuffer()
endfunction

function! s:SwapDown()
    call s:Swap(line("."), line(".")+1)
    call s:RedrawBuffer()
endfunction

" TODO: this is still bugged
" it mostly works up the manipulation up/down isn't right
function! s:ScratchList()
    new
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nowrap
    setlocal noswapfile

    call s:RedrawBuffer()

    augroup FrogBuffer
        autocmd!
        autocmd BufEnter <buffer> stopinsert

        " manipulation
        nnoremap <buffer> <C-j> :call <SID>SwapDown()<CR>
        nnoremap <buffer> <C-k> :call <SID>SwapUp()<CR>
        nnoremap <buffer> dd :call <SID>RemoveFromBuffer()<CR>

        nnoremap <buffer> <CR> :call frog#GoTo(line("."))<CR>

        " quitting operations
        nnoremap <buffer> q :bd<CR>
        nnoremap <buffer> <ESC> :bd<CR>
    augroup END
endfunction

let s:popup_id = -1
let s:selected_index = 0

function! s:PopupKeyHandler(id, key) abort
    if a:key ==# 'j' || a:key ==# "\<Down>"
        let s:selected_index = (s:selected_index + 1) % len(s:frog_files)
        call s:DrawPopup()
    elseif a:key ==# 'k' || a:key ==# "\<Up>"
        let s:selected_index = (s:selected_index - 1 + len(s:frog_files)) % len(s:frog_files)
        call s:DrawPopup()
    elseif a:key ==# 'J'
        call s:Swap(s:selected_index, s:selected_index+1)
        call s:DrawPopup()
    elseif a:key ==# 'K'
        call s:Swap(s:selected_index, s:selected_index-1)
        call s:DrawPopup()
    elseif a:key ==# 'd' || a:key ==# 'D'
        call remove(s:frog_files, s:selected_index)
        let s:selected_index = min([s:selected_index, len(s:frog_files)-1])
        call s:DrawPopup()
    elseif a:key ==# "\<Esc>" || a:key ==# 'q'
        call popup_close(s:popup_id)
        let s:popup_id = -1
    elseif a:key ==# "\<CR>"
        call popup_close(s:popup_id)
        let s:popup_id = -1
        call frog#GoTo(s:selected_index+1)
    endif
    return v:true
endfunction

function! s:DrawPopup() abort
    if s:popup_id != -1
        call popup_close(s:popup_id)
    endif
    let display = s:LineList(s:selected_index)
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

" open an interative list so that the user can reorder
function! frog#InteractiveList()
    if g:frog_use_popup
        call s:DrawPopup()
    else
        call s:ScratchList()
    endif
endfunction
