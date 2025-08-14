let g:frog_files = []
let g:use_args = 1

if g:use_args
    let g:frog_files = argv()
endif

function! AddFile()
    let f = expand("%:p")
    if index(g:frog_files, f) == -1
        echo "[ribbit] adding: " . f
        call add(g:frog_files, f)
    else
        echo "[ribbit] already in list"
    endif
endfunction

function! GoTo(idx)
    echo "going to " . (a:idx + 1)
    if a:idx < len(g:frog_files)
        execute 'edit' g:frog_files[a:idx]
    else
        echo "[ribbit] no file found at " . a:idx
    endif
endfunction

    " let args = argv()
    " for arg in args
    "     echo arg
    " endfor

function! List()
    if len(g:frog_files) == 0
        echo "[ribbit] no frog files"
        return
    endif
    echo "[ribbit]"
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

    let targetline = lnum + a:direction

    let current = getline(lnum)
    let target = getline(targetline)
    call setline(lnum, target)
    call setline(targetline, current)
    call cursor(targetline, 1)
    " call SyncScratcher()
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

function! GetWindowHeight()
    let header_lines = 5
    let max_lines = 15
    let desired_height = header_lines + len(g:frog_files)
    return desired_height
endfunction

function! Scratcher()
    if len(g:frog_files) == 0
        echo "[ribbit] no frog files"
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
    augroup END
endfunction


nnoremap <C-a> :call AddFile()<CR>
nnoremap <C-l> :call Scratcher()<CR>
nnoremap <C-p> :call List()<CR>

nnoremap <Space>1 :call GoTo(0)<CR>
nnoremap <Space>2 :call GoTo(1)<CR>
nnoremap <Space>3 :call GoTo(2)<CR>
nnoremap <Space>4 :call GoTo(3)<CR>
