if !exists('g:frog_use_args')
    let g:frog_use_args = 1
endif

if !exists('g:frog_use_popup')
    let g:frog_use_popup = has('popupwin')
endif

nnoremap <Space>a :call frog#AddFile()<CR>
nnoremap <Space>p :call frog#List()<CR>
nnoremap <C-l> :call frog#InteractiveList()<CR>
nnoremap <Space>1 :call frog#GoTo(0)<CR>
nnoremap <Space>2 :call frog#GoTo(1)<CR>
nnoremap <Space>3 :call frog#GoTo(2)<CR>
nnoremap <Space>4 :call frog#GoTo(3)<CR>
