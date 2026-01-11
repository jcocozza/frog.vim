if !exists('g:frog_use_args')
    " when set to 1, will auto populate the list
    " with the files passed in from args
    let g:frog_use_args = 1
endif

if !exists('g:frog_use_popup')
    let g:frog_use_popup = has('popupwin')
endif

if !exists('g:frog_auto_update')
    " when set to 1, will save cursor position each time you leave the
    " buffer
    let g:frog_auto_update = 1
endif

nnoremap <Leader>a :call frog#AddFile()<CR>
nnoremap <Leader>p :call frog#Print()<CR>
nnoremap <Leader>l :call frog#InteractiveList()<CR>
nnoremap <Leader>1 :call frog#GoTo(1)<CR>
nnoremap <Leader>2 :call frog#GoTo(2)<CR>
nnoremap <Leader>3 :call frog#GoTo(3)<CR>
nnoremap <Leader>4 :call frog#GoTo(4)<CR>

if g:frog_auto_update
    augroup FrogAutoUpdate
        autocmd!
        autocmd BufLeave * call frog#Update(v:false)
    augroup END
endif
