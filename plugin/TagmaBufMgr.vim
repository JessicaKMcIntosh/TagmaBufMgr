" vim:foldmethod=marker
" =============================================================================
" File:         TagmaBufMgr.vim (Plugin)
" Last Changed: Thu, Oct 13, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Simple Buffer Manager
"
"               Similar to existing managers but aims to be simpler in
"               interface and code. In particular the window history is
"               maintained when switching buffers and refreshing. So <C-W>p
"               and <C-W>n work as expected.
"
"               Provides a PopUp menu interface for switching buffers and
"               controlling the Buffer Manager.
"
"               Attempts to cache as much inforation about buffers as
"               possible. This results in running less code each time the
"               Manager functions are executed.
" =============================================================================

" Section: Initialization

" Only load once. {{{1
if exists('g:TagmaBufMgrloaded') || &cp
    finish
endif
let g:TagmaBufMgrloaded= 1

" Defaults {{{1
function! s:SetDefault(option, default)
    if !exists(a:option)
        let l:cmd = 'let ' . a:option . '='
        let l:type = type(a:default)
        if l:type == type("")
            let l:cmd .= '"' . a:default . '"'
        elseif l:type == type(0)
            let l:cmd .= a:default
        elseif l:type == type([])
            let l:cmd .= string(a:default)
        endif
        exec l:cmd
    endif
endfunction

" Display the Buffer Manager Automatically.
call s:SetDefault('g:TagmaBufMgrAutoDisplay',   1)

" Show buffer numbers in the buffer list.
call s:SetDefault('g:TagmaBufMgrBufferNumbers', 1)

" Close the manager window after selecting a buffer.
call s:SetDefault('g:TagmaBufMgrCloseSelect',   0)

" Closing the last window (besides the Buffer Manager) quits Vim.
" Otherwise a new window will be created.
call s:SetDefault('g:TagmaBufMgrLastWindow',    0)

" The Manager Window location, defaults to the top.
" (T)op, (B)ottom, (L)eft, (R)ight, (F)loat
call s:SetDefault('g:TagmaBufMgrLocation',      'T')

" Map Ctrl-Arrow keys to window navigation.
call s:SetDefault('g:TagmaBufMgrMapCArrow',     1)

" Map Ctrl-[hjkl] keys to window navigation.
call s:SetDefault('g:TagmaBufMgrMapChjkl',      1)

" Map Ctrl-Tab and Ctrl-Shift-Tab to switch buffers in the current window.
call s:SetDefault('g:TagmaBufMgrMapCTab',       1)

" Key map prefix for all commands.
" Set to an empty string to disable keymaps.
call s:SetDefault('g:TagmaBufMgrPrefix',        '<Leader>tb')

" Enable the addition to the Right-Click PopUp menu.
call s:SetDefault('g:TagmaBufMgrPopUp',         (has('menu') ? 1 : 0))
if g:TagmaBufMgrPopUp && !has('menu')
    let g:TagmaBufMgrPopUp = 0
endif

" The Manager Window Width, when at the Left or Right.
" Set to 0 to disable resizing.
call s:SetDefault('g:TagmaBufMgrWidth',         25)

" No need for the function any longer.
delfunction s:SetDefault

" Inernal settings. {{{1

" The Buffer Manager Buffer Number.
let g:TagmaBufMgrBufNr      = -1

" The Buffer Manager Buffer Name.
let g:TagmaBufMgrBufName    = '_TagmaBufMgr_'

" Auto Display & Popup {{{1

if g:TagmaBufMgrAutoDisplay
    " Display the Manager Window.
    autocmd VimEnter * call s:ToggleMgr('A')
elseif g:TagmaBufMgrPopUp
    " Generate the PopUp Menu and initialize the refresh.
    autocmd VimEnter * call s:InitMgrRefresh()|call s:BufCacheRefresh()
endif

" User Commands {{{1

" Close the Buffer Manager.
command! -nargs=0 MgrClose          call s:CloseMgr()

" Open the Buffer Manager.
command! -nargs=0 MgrOpen           call s:OpenMgr('M')

" Show the Buffer PopUp menu.
command! -nargs=0 MgrPopUp          call s:ShowPopUp()

" Toggle the Buffer Manager.
command! -nargs=0 MgrToggle         call s:ToggleMgr('M')

" Refresh the Buffer Manager. (Should not be necessary.)
command! -nargs=0 MgrUpdate         call s:BufCacheRefresh()

" Plugin Mappings {{{1
if !hasmapto('<SID>CloseMgr()')
    noremap <unique> <script> <Plug>CloseMgr        :call <SID>CloseMgr()<CR>
endif
if !hasmapto("<SID>OpenMgr('M')")
    noremap <unique> <script> <Plug>OpenMgr         :call <SID>OpenMgr('M')<CR>
endif
if !hasmapto("<SID>ShowPopUp()") && has('menu')
    noremap <unique> <script> <Plug>ShowPopUp       :call <SID>ShowPopUp()<CR>
endif
if !hasmapto("<SID>ToggleMgr('M')")
    noremap <unique> <script> <Plug>ToggleMgr       :call <SID>ToggleMgr('M')<CR>
endif
if !hasmapto("<SID>BufCacheRefresh()")
    noremap <unique> <script> <Plug>UpdateMgr       :call <SID>BufCacheRefresh()<CR>
endif

" Global Key Mappings {{{1
if g:TagmaBufMgrPrefix != ''
    if !hasmapto('<Plug>CloseMgr')
        exec 'map <silent> <unique> ' . g:TagmaBufMgrPrefix . 'c <Plug>CloseMgr'
    endif

    if !hasmapto('<Plug>OpenMgr')
        exec 'map <silent> <unique> ' . g:TagmaBufMgrPrefix . 'o <Plug>OpenMgr'
    endif

    if !hasmapto('<Plug>ShowPopUp')
        exec 'map <silent> <unique> ' . g:TagmaBufMgrPrefix . 'p <Plug>ShowPopUp'
    endif

    if !hasmapto('<Plug>ToggleMgr')
        exec 'map <silent> <unique> ' . g:TagmaBufMgrPrefix . 't <Plug>ToggleMgr'
    endif

    if !hasmapto('<Plug>UpdateMgr')
        exec 'map <silent> <unique> ' . g:TagmaBufMgrPrefix . 'u <Plug>UpdateMgr'
    endif
endif

" Navigation Key Mappings {{{1

" Map Ctrl-Arrow keys to window navigation.
if g:TagmaBufMgrMapCArrow
    nnoremap <silent> <C-Up>             :wincmd k<CR>
    nnoremap <silent> <C-Down>           :wincmd j<CR>
    nnoremap <silent> <C-Left>           :wincmd h<CR>
    nnoremap <silent> <C-Right>          :wincmd l<CR>

    inoremap <silent> <C-Up>        <Esc>:wincmd k<CR>
    inoremap <silent> <C-Down>      <Esc>:wincmd j<CR>
    inoremap <silent> <C-Left>      <Esc>:wincmd h<CR>
    inoremap <silent> <C-Right>     <Esc>:wincmd l<CR>
endif

" Map Ctrl-[hjkl] keys to window navigation.
if g:TagmaBufMgrMapChjkl
    nnoremap <silent> <C-k>              :wincmd k<CR>
    nnoremap <silent> <C-j>              :wincmd j<CR>
    nnoremap <silent> <C-h>              :wincmd h<CR>
    nnoremap <silent> <C-l>              :wincmd l<CR>

    inoremap <silent> <C-k>         <Esc>:wincmd k<CR>
    inoremap <silent> <C-j>         <Esc>:wincmd j<CR>
    inoremap <silent> <C-h>         <Esc>:wincmd h<CR>
    inoremap <silent> <C-l>         <Esc>:wincmd l<CR>
endif

" Map Ctrl-Tab and Ctrl-Shift-Tab to switch buffers in the current window.
if g:TagmaBufMgrMapCTab
    nnoremap <silent> <C-TAB>           :call <SID>TabBuffer('N')<CR>
    nnoremap <silent> <C-S-TAB>         :call <SID>TabBuffer('P')<CR>

    inoremap <silent> <C-TAB>      <Esc>:call <SID>TabBuffer('N')<CR>
    inoremap <silent> <C-S-TAB>    <Esc>:call <SID>TabBuffer('P')<CR>
endif

"}}}

" Section: Functions

" Function: s:BufCacheEntry(...)    -- Create/Update Cache Entry {{{1
" Create/Update an entry in the buffer cache for a specific buffer.
" mode is what to do with the entry.
"   A = Add as new. (Also if there is no cache entry for the buffer.)
"   M = Update the modification flag. (Always updated.)
"   L = Leaving a buffer.
"   S = Update the status (Current or not).
" buf_nr is the buffer to work with.
function! s:BufCacheEntry(mode, buf_nr)
    " Don't update the Manager Buffer.
    if a:buf_nr == g:TagmaBufMgrBufNr
        return 0
    endif

    " Get the Cache entry for this buffer.
    if has_key(g:TagmaBufMgrBufCache, a:buf_nr)
        " Existing Cache Entry.
        let l:cache_mode = a:mode
        let l:cache = g:TagmaBufMgrBufCache[a:buf_nr]
    else
        " New Cache entry.
        let l:cache_mode = 'A'
        let l:cache = {}
    endif

    " Modified Status. Always update.
    let l:cache['mod'] = getbufvar(a:buf_nr, '&modified')

    if l:cache_mode == 'L'
        " When leaving a buffer clear its current status.
        let l:cache['cur'] = 0
    else
        " Current Status.
        if l:cache_mode == 'A' || l:cache_mode == 'S'
            let l:cache['cur'] = (a:buf_nr == bufnr('%'))
            let l:cache['load'] = bufloaded(a:buf_nr)
        endif

        " The Buffer Name.
        if l:cache_mode == 'A'
            let l:buf_name = s:FindBufName(a:buf_nr)
            if l:buf_name == '' 
                return 0
            endif
            let l:cache['name'] = l:buf_name
        endif
    endif

    " Buffer Type. This can change, like when opening :help.
    let l:buf_type = getbufvar(a:buf_nr, '&buftype')
    if l:cache_mode == 'A' || l:cache['type'] != l:buf_type
        let l:cache['type'] = l:buf_type
        let l:cache['flags'] = 
                    \ (l:buf_type == 'help' ? '?' : '') .
                    \ (l:buf_type == 'quickfix' ? '$' : '')
    endif

    " Create the buffer entry from the cache data.
    let l:cache['entry'] = s:BufCacheFormat(l:cache, a:buf_nr)

    " Save the cache data to the global cache.
    let g:TagmaBufMgrBufCache[a:buf_nr] = l:cache

    " Return true.
    return 1
endfunction

" Function: s:BufCacheFormat(..)    -- Format Cache Entry {{{1
" Format a cache entry.
" The cache hash and buffer number for the entry is passed in.
function! s:BufCacheFormat(cache, buf_nr)
    " Return the formatted entry.
    return        '[' . (a:cache['mod'] ? '+' : '') .
                \ (g:TagmaBufMgrBufferNumbers ? a:buf_nr . ':' : '') .
                \ a:cache['name'] . a:cache['flags'] .
                \ (a:cache['load'] ? '' : '&') .
                \ (a:cache['cur'] ? '!' : '') . ']'

endfunction

" Function: s:BufCacheRefresh()     -- Full Cache Refresh {{{1
" Full refresh of the Buffer Cache.
function! s:BufCacheRefresh()
    " Prepare to loop.
    let l:num_buffers = bufnr('$')
    let l:prev_buf = winbufnr(winnr('#'))
    let l:cur_buf = 0

    " Clear the Buffer Cache.
    let g:TagmaBufMgrBufCache = {}

    " Loop over all buffers and build a list.
    while(l:cur_buf < l:num_buffers)
        " The counting is done early so we can bail quickly if this is the
        " Manager Buffer or one we don't want listed.
        let l:cur_buf += 1
        let l:buf_type = getbufvar(l:cur_buf, '&buftype')
        if l:cur_buf == g:TagmaBufMgrBufNr || !bufexists(l:cur_buf) ||
                    \ (l:buf_type == 'help' && !bufloaded(l:cur_buf)) ||
                    \ (l:buf_type != 'help' && !buflisted(l:cur_buf))
            continue
        endif

        " Create the Buffer Cache Entry.
        call s:BufCacheEntry('A', l:cur_buf)
        continue
    endwhile

    " Update the PopUp Menu.
    if g:TagmaBufMgrPopUp
        call s:PopUpMenu()
    endif

    " Display the list in the Manager Window.
    call s:DisplayList()
endfunction

" Function: s:BufCacheUpdate(...)   -- Update Cache Entry {{{1
" Update a Buffer Cache entry then update the list and PopUp.
" If mode is M do a quick modification check.
" If mode is d delete the buffer.
" If mode is u mark the buffer unloaded.
" Otherwise mode is passed to BufCacheEntry.
function! s:BufCacheUpdate(mode, buf_nr)
    " Is the buffer in the cache?
    let l:in_cache = has_key(g:TagmaBufMgrBufCache, a:buf_nr)

    " Do a quick check for modification.
    " Since this will be called often make it as quick as possible.
    if a:mode == 'M' && (!l:in_cache ||
                        \ g:TagmaBufMgrBufCache[a:buf_nr]['mod'] ==
                        \ getbufvar(a:buf_nr, '&modified'))
        return
    elseif a:mode == 'd' ||
                \ (a:mode == 'u' && getbufvar(a:buf_nr, '&buftype') == 'help')
        " Delete the buffer from the list.
        " Help buffers need to be deleted on unload.
        silent! call remove(g:TagmaBufMgrBufCache, a:buf_nr)
    elseif a:mode == 'u' && l:in_cache
        " Mark the buffer unloaded and update the entry.
        let g:TagmaBufMgrBufCache[a:buf_nr]['load'] = 0
        let g:TagmaBufMgrBufCache[a:buf_nr]['entry'] = 
            \ s:BufCacheFormat(g:TagmaBufMgrBufCache[a:buf_nr], a:buf_nr)
    else
        " Update the entry.
        " If there was no change just return.
        if !s:BufCacheEntry(a:mode, a:buf_nr)
            return
        endif
    endif

    " If checking for modification don't update the PopUp.
    if a:mode != 'M' && g:TagmaBufMgrPopUp
        " Update the PopUp Menu.
        call s:PopUpMenu()
    endif

    " Display the list in the Manager Window.
    call s:DisplayList()
endfunction

" Function: BufMgrToolTips()        -- Buffer Tool Tips {{{1
function! BufMgrToolTips()
    " Get the buffer number the mouse is over.
    if v:beval_text =~ '^\d\+$'
        let l:buf_nr = v:beval_text
    else
        let l:tip_line = getbufline(v:beval_bufnr, v:beval_lnum, v:beval_lnum)
        let l:buf_nr = strpart(l:tip_line[0], 0, v:beval_col)
        let l:buf_nr = substitute(l:buf_nr, '.*\[+\?\(\d\+\)[^\[]\+$', '\1', '')
    endif
    let l:buf_nr = l:buf_nr + 0

    " If the buffer is not in the cache just return.
    if !has_key(g:TagmaBufMgrBufCache, l:buf_nr)
        return ''
    endif

    " Build the information for the Tool Tip.
    let l:buf_name = g:TagmaBufMgrBufCache[l:buf_nr]['name']
    let l:buf_type = getbufvar(l:buf_nr, '&filetype')
    let l:buf_file = expand('#' . l:buf_nr)
    if l:buf_file == ''
        let l:buf_file = 'N/A'
    else
        let l:buf_file = fnamemodify(l:buf_file, ':p:~')
    endif

    let l:tool_tip = [
                \ 'Buffer [' . l:buf_name . '] # ' . l:buf_nr .
                    \ (l:buf_nr == bufnr('%') ? ' (Current)' : ''),
                \ 'File Name: ' . l:buf_file,
                \ 'Type: [' . (l:buf_type == '' ? 'N/A' : l:buf_type) . '] ' .
                    \ 'Format: [' . getbufvar(l:buf_nr, '&fileformat') . ']',
                \ ]

    if getbufvar(l:buf_nr, '&modified')
        call add(l:tool_tip, 'Modified!')
    endif

    if getbufvar(l:buf_nr, '&readonly')
        call add(l:tool_tip, 'Readonly')
    endif

    " Return the tooltip.
    return join(l:tool_tip, has('balloon_multiline') ? "\n" : ' ')
endfunction

" Function: s:CloseMgr()            -- Close Manager Window {{{1
function! s:CloseMgr()
    " See if the Manager Window is visible.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr != -1
        exec l:mgr_winnr . 'wincmd w'
        wincmd c
    endif
endfunction

" Function: s:CreateMgrWin()        -- Create Manager Window {{{1
" Create the Manager Window in the desired location.
" Controlled by the setting g:TagmaBufMgrLocation.
function! s:CreateMgrWin()
    " Set the orientation and create the Manager Window.
    let g:TagmaBufMgrOrient = 'H'
    if g:TagmaBufMgrLocation == 'B'
        exec 'silent! botright split' . g:TagmaBufMgrBufName
    elseif g:TagmaBufMgrLocation == 'T'
        exec 'silent! topleft split' . g:TagmaBufMgrBufName
    else
        let g:TagmaBufMgrOrient = 'V'
        if g:TagmaBufMgrLocation == 'L'
            exec 'silent! topleft vsplit' . g:TagmaBufMgrBufName
        elseif g:TagmaBufMgrLocation == 'R'
            exec 'silent! botright vsplit' . g:TagmaBufMgrBufName
        elseif g:TagmaBufMgrLocation == 'F'
            exec 'split' . g:TagmaBufMgrBufName
        endif
    endif

    " Fix the window size if not floating.
    if g:TagmaBufMgrLocation != 'F'
        setlocal winfixheight
        setlocal winfixwidth
    endif
endfunction

" Function: s:DeleteBuf()           -- Delete Buffer {{{1
" Delete a Buffer when the user requests.
function! s:DeleteBuf()
    " Determine the buffer to switch to.
    let l:buf_nr = s:GetBufNr()
    if l:buf_nr == ''
        return
    endif

    " Back to the previous window.
    exec winnr('#') . 'wincmd w'

    " Delete the buffer.
    exec 'bd ' l:buf_nr
endfunction

" Function: s:DisplayList()         -- Display Buffer List {{{1
" Display the buffer list in the Manager Window.
function! s:DisplayList()
    " If the Manager is not visible nothing to do.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1 
        return
    endif

    " Save the " register.
    let l:save_quote = @"

    " If not already in the Manager Window save the current and previous
    " windows then switch to the Manager.
    if winnr() != l:mgr_winnr
        let l:prev_win = [winnr('#'), winnr()]
        exec l:mgr_winnr . 'wincmd w'
    endif

    " Generate the list from the cache.
    let l:buf_list = values(map(copy(g:TagmaBufMgrBufCache),
                              \ "g:TagmaBufMgrBufCache[v:key]['entry']"))

    " Clear the current buffer list.
    silent! normal! ggdG

    "  Write, Format, Resize...
    if g:TagmaBufMgrOrient == 'H'
        call setline(1, join(l:buf_list))
        exec 'setlocal textwidth=' . &columns
        silent! normal! gqqgg
        exec 'resize ' . line('$')
    else
        call append(0, l:buf_list)
        normal! Gddgg
        if g:TagmaBufMgrWidth > 0 && g:TagmaBufMgrLocation != 'F'
            exec 'vertical resize ' . g:TagmaBufMgrWidth
        endif
    endif

    " Restore the " register.
    let @" = l:save_quote

    " If we switched windows go back.
    if exists('l:prev_win')
        exec l:prev_win[0] . 'wincmd w'
        exec l:prev_win[1] . 'wincmd w'
    endif
endfunction

" Function: s:FindBufName(...)      -- Find Buffer Name {{{1
" Finds the name of a buffer.
" Returns an empty string if it can not be found.
function! s:FindBufName(buf_nr)
    let l:buf_name = fnamemodify(bufname(a:buf_nr), ':t')
    if l:buf_name == ''
        " Empty name, check the full :ls list.
        redir => full_list
        silent! ls
        redir END
        let l:buf_name = substitute(l:full_list, '^.*\D' . a:buf_nr .
                    \ '\D[^"]\+"\[\([^\]]\+\)\]".*$', '\1', '')
        if l:buf_name == l:full_list
            " Unable to find a name.
            return ''
        endif
    endif
    return l:buf_name
endfunction

" Function: s:GetBufNr()            -- Buffer number under cursor {{{1
" Returns the buffer number for the item under the cursor.
function! s:GetBufNr()
    let l:temp = @"
    let @" = ''
    normal! ""yi[
    let l:buf_nr = substitute(@", '^+\?\(\d\+\):.*$', '\1', '')
    let @" = l:temp
    return l:buf_nr
endfunction

" Function: s:InitMgrBuffer()       -- Initialize Manager Buffer {{{1
" Initialize the Manager Buffer and the auto refresh if not set.
function! s:InitMgrBuffer()
    " Buffer Settings.
    setlocal bufhidden=hide
    setlocal buftype=nofile
    setlocal foldcolumn=0
    setlocal matchpairs=
    setlocal nobuflisted
    setlocal nonumber
    setlocal noswapfile
    setlocal nowrap
    setlocal formatoptions=

    " Syntax Highlighting.
    if has('syntax')
        call s:InitMgrSyntax()
    endif

    " Make sure the cache and Auto Rrefresh were setup.
    if !exists('g:TagmaBufMgrBufCache')
        call s:InitMgrRefresh()
    endif

    " Check if there are no other windows when entering the Bufffer Manager.
    autocmd BufEnter <buffer> call s:LastWindow()
    
    " Perform a full refresh when entering the Buffer Manager.
    autocmd BufEnter <buffer> call s:BufCacheRefresh()
    
    " Set the buffer keymaps.
    call s:InitMgrKeys()

    " Balloon/Tool Tips settings.
    if has('balloon_eval')
        setlocal bexpr=BufMgrToolTips()
        setlocal ballooneval
    endif

    " Note that the initialization has been performed.
    let b:TagmaBufMgrInit = 1
endfunction

" Function: s:InitMgrKeys()         -- Initialize Manager Keys Maps {{{1
function! s:InitMgrKeys()
    " Nagivate between buffer entries.
    nnoremap <buffer> <silent> <TAB>            :call search('\[', 'w')<CR>
    nnoremap <buffer> <silent> l                :call search('\[', 'w')<CR>
    nnoremap <buffer> <silent> w                :call search('\[', 'w')<CR>
    nnoremap <buffer> <silent> <S-TAB>          :call search('\[', 'bw')<CR>
    nnoremap <buffer> <silent> h                :call search('\[', 'bw')<CR>
    nnoremap <buffer> <silent> b                :call search('\[', 'bw')<CR>

    " Delete buffer entres.
    nnoremap <buffer> <silent> D                :call <SID>DeleteBuf()<CR>
    nnoremap <buffer> <silent> d                :call <SID>DeleteBuf()<CR>

    " Open buffer entries.
    nnoremap <buffer> <silent> <CR>             :call <SID>SwitchBuf('N')<CR>
    nnoremap <buffer> <silent> S                :call <SID>SwitchBuf('S')<CR>
    nnoremap <buffer> <silent> s                :call <SID>SwitchBuf('S')<CR>
    nnoremap <buffer> <silent> V                :call <SID>SwitchBuf('V')<CR>
    nnoremap <buffer> <silent> v                :call <SID>SwitchBuf('V')<CR>

    " Return to the previous window.
    nnoremap <buffer> <silent> p                :wincmd p<CR>
    nnoremap <buffer> <silent> P                :wincmd p<CR>

    " Close Buffer Manager.
    nnoremap <buffer> <silent> C                :call <SID>CloseMgr()<CR>
    nnoremap <buffer> <silent> c                :call <SID>CloseMgr()<CR>

    " Manager Buffer Specific Menu.
    if has('menu')
        anoremenu <silent>  ]BufMgr.&Close\ Mgr         :call <SID>CloseMgr()<CR>
        anoremenu <silent>  ]BufMgr.&Refresh\ Mgr       :call <SID>BufCacheRefresh()<CR>
        anoremenu           ]BufMgr.-Separator-         :
        anoremenu <silent>  ]BufMgr.Switch&To           :call <SID>SwitchBuf('N')<CR>
        anoremenu <silent>  ]BufMgr.&Split              :call <SID>SwitchBuf('S')<CR>
        anoremenu <silent>  ]BufMgr.&Vertical           :call <SID>SwitchBuf('V')<CR>
        anoremenu <silent>  ]BufMgr.&Delete             :call <SID>DeleteBuf()<CR>
    endif

    " Mouse Clicks to switch buffers.
    if has('mouse')
        nnoremap <buffer> <silent> <2-LEFTMOUSE>    :call <SID>SwitchBuf('N')<CR>
        nnoremap <buffer> <silent> <C-LEFTMOUSE>    :call <SID>SwitchBuf('S')<CR>
        nnoremap <buffer> <silent> <S-LEFTMOUSE>    :call <SID>SwitchBuf('V')<CR>
        nnoremap <buffer> <silent> <RIGHTMOUSE>     :popup! ]BufMgr<CR>
    endif
endfunction

" Function: s:InitMgrSyntax()       -- Initialize Syntax {{{1
" Setup the syntax highlighting for the Manager.
function! s:InitMgrSyntax()
    syn match TagmaBufMgrPlain      '\[[^\]]\+\]'
    syn match TagmaBufMgrActive     '\[[^\]]\+!\]'
    syn match TagmaBufMgrChanged    '\[+[^\]]\+\]'
    syn match TagmaBufMgrChgAct     '\[+[^\]]\+!\]'
    syn match TagmaBufMgrHelp       '\[[^\]]\+?\]'
    syn match TagmaBufMgrQFoLL      '\[[^\]]\+\$\]'
    syn match TagmaBufMgrUnLoaded   '\[[^\]]\+&\]'

    hi def link TagmaBufMgrPlain    Comment
    hi def link TagmaBufMgrActive   Identifier
    hi def link TagmaBufMgrChanged  String
    hi def link TagmaBufMgrChgAct   Error
    hi def link TagmaBufMgrHelp     Type
    hi def link TagmaBufMgrQFoLL    Special
    hi def link TagmaBufMgrUnloaded Statement
endfunction

" Function: s:InitMgrRefresh()      -- Initialize Manager Refresh {{{1
" Creates the buffer cache. (How we know Refresh was setup.)
" Creates the auto commands for Refresh.
" Creates the static Menue entries for the PopUp Menu.
function! s:InitMgrRefresh()
    " The Buffer Cache.
    let g:TagmaBufMgrBufCache = {}

    " Set the other refresh events.
    autocmd BufAdd          *   call s:BufCacheUpdate('A', bufnr('%'))
    autocmd BufEnter        *   call s:BufCacheUpdate('S', bufnr('%'))
    autocmd BufLeave        *   call s:BufCacheUpdate('L', bufnr('%'))
    autocmd BufDelete       *   call s:BufCacheUpdate('d', expand('<abuf>'))
    autocmd BufUnload       *   call s:BufCacheUpdate('u', expand('<abuf>'))

    " Check for modification changes.
    autocmd BufWritePost,CursorHold,CursorHoldI *
                              \ call s:BufCacheUpdate('M', expand('<abuf>'))

    " Static PopUp Menu entries.
    if g:TagmaBufMgrPopUp
        nnoremenu          PopUp.-Separator-        :
        nnoremenu <silent> PopUp.&Toggle\ BufMgr    :call <SID>ToggleMgr('M')<CR>
        nnoremenu <silent> PopUp.&Refresh\ BufMgr   :call <SID>BufCacheRefresh()<CR>
        nnoremenu          PopUp.-Separator-        :
    endif
endfunction

" Function: s:LastWindow()          -- Check for last Window close {{{1
" If the last window, excluding the buffer manager, was closed either quit Vim
" or open a fresh window.
" If the Manager Window is not visible does nothing.
" Controlled by g:TagmaBufMgrLastWindow.
function! s:LastWindow()
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1
        return
    endif

    if winbufnr(2) == -1
        if g:TagmaBufMgrLastWindow
            qall
        else
            exec 'resize ' . &lines
            new
            call s:CloseMgr()
            call s:OpenMgr('A')
        endif
    endif
endfunction

" Function: s:OpenMgr(...)          -- Open/Create Manager Window {{{1
" The mode determines what window to remain in.
"   A = Automatic open. Return to the previous window.
"   M = Manual open. Stay in the Manager Window.
function! s:OpenMgr(mode)
    " Nothing to do if already in the Manager Window.
    let l:winnr = bufwinnr(g:TagmaBufMgrBufName)
    if l:winnr == winnr()
        return
    endif

    " Open/Create the buffer.
    if l:winnr == -1
        " Create/Switch to the buffer and window.
        call s:CreateMgrWin()
    else
        " Switch to the window.
        execute l:winnr . 'wincmd w'
    endif

    " Save the manager buffer # for later use.
    let g:TagmaBufMgrBufNr= bufnr(g:TagmaBufMgrBufName)

    " Make sure the buffer has been initialized.
    " Sometimes buffers can still exist but be wiped...
    if !exists('b:TagmaBufMgrInit')
        call s:InitMgrBuffer()
    endif

    " Perform a full refresh of the Cache.
    call s:BufCacheRefresh()

    " If opened automatically return to the previous window.
    if toupper(a:mode) == 'A'
        wincmd p
    endif
endfunction

" Function: s:PopUpMenu(list)       -- PopUp Menu Addition {{{1
" Create the PopUp Menu additions for switching buffers.
" Uses the Buffer Cache g:TagmaBufMgrBufCache.
function! s:PopUpMenu()

    " Clear the old PopUp Menu.
    silent! unmenu PopUp.SwitchTo

    " Add the buffer list to the PopUp Menu.
    for l:cur_buf in sort(keys(g:TagmaBufMgrBufCache))
        " Escape the buffer name.
        let l:buf_name = g:TagmaBufMgrBufCache[l:cur_buf]['name']
        let l:buf_name = escape(l:buf_name . ' (' . l:cur_buf . ')', '. \')

        " Add the PopUp Menu Entry.
        exec 'nnoremenu <silent> PopUp.SwitchTo.' .
                    \ substitute(l:buf_name, '\s', '_', 'g') .
                    \ ' :b' . l:cur_buf . '<CR>'
    endfor
endfunction

" Function: s:ShowPopUp()           -- Show PopUp Menu {{{1
" Show the Buffer PopUp menu.
function! s:ShowPopUp()
    if has('menu')
        silent! popup PopUp.SwitchTo
    else
        echohl warningmsg
        echo 'Menus are not supported in this version of VIM.'
        echohl NONE
    endif
endfunction

" Function: s:SwitchBuf(...)        -- Switch Buffers {{{1
" The mode determins how to open the window.
"   N = Normal, open in the previous window.
"   S = Split open.
"   V = Vertical Split open.
function! s:SwitchBuf(mode)
    " Determine the buffer to switch to.
    let l:buf_nr = s:GetBufNr()
    if l:buf_nr == ''
        return
    endif

    " Back to the previous window.
    exec winnr('#') . 'wincmd w'

    " Switch to the buffer according to the mode.
    if a:mode == 'N'
        exec 'b' . l:buf_nr
    elseif a:mode == 'S'
        exec 'split +b' . l:buf_nr
    elseif a:mode == 'V'
        exec 'vsplit +b' . l:buf_nr
    endif

    " Close the Manager Window if requested.
    if g:TagmaBufMgrCloseSelect
        call s:CloseMgr()
    endif
endfunction

" Function: s:TabBuffer(...)        -- Tab Next/Prev Buffer {{{1
" Called from Ctrl-Tab or Ctrl-Shift-Tab to switch buffers.
" direction is which buffer to switch to.
"   N = Next Buffer
"   P = Previous Buffer
function! s:TabBuffer(direction)
    let l:dir_func = (a:direction == 'N' ? 'bnext' : 'bprev')
    exec l:dir_func
    if bufnr('%') == g:TagmaBufMgrBufNr
        exec l:dir_func
    endif
endfunction

" Function: s:ToggleMgr(...)        -- Toggle Manager Window {{{1
" The mode is passed to OpenMgr.
function! s:ToggleMgr(mode)
    " See if the Manager Window is visible.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1
        call s:OpenMgr(a:mode)
        return
    endif

    " Close the Manager Window.
    call s:CloseMgr()
endfunction
