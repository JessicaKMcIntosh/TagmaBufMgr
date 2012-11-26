" vim:foldmethod=marker
" =============================================================================
" File:         TagmaBufMgr.vim (Plugin)
" Last Changed: Mon Nov 26 02:05 PM 2012 EST
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Simple Buffer Manager
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
        execute 'let ' . a:option . '=' . string(a:default)
    endif
endfunction

" Display the Buffer Manager Automatically.
call s:SetDefault('g:TagmaBufMgrAutoDisplay',   1)

" Show buffer numbers in the buffer list.
call s:SetDefault('g:TagmaBufMgrBufferNumbers', 1)

" Close the manager window after selecting a buffer.
call s:SetDefault('g:TagmaBufMgrCloseSelect',   0)

" Show the Manager Window as the last line without a status line.
call s:SetDefault('g:TagmaBufMgrLastLine',      0)

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

" Map Ctrl-[hjkl] keys to switch buffers.
call s:SetDefault('g:TagmaBufMgrMapChjklbuf',   0)
if g:TagmaBufMgrMapChjkl
    let g:TagmaBufMgrMapChjklbuf = 0
endif

" Map Ctrl-Tab and Ctrl-Shift-Tab to switch buffers in the current window.
call s:SetDefault('g:TagmaBufMgrMapCTab',       1)

" Map Mouse Foward/Back to switch buffers in the current window.
call s:SetDefault('g:TagmaBufMgrMapMouseFB',    1)

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

" The default status line text.
call s:SetDefault('g:TagmaBufMgrStatusLine',    'Tagma Buffer Manager - See `:help TagmaBufMgr` for more information.')

" No need for the function any longer.
delfunction s:SetDefault

" Internal settings. {{{1

" The Buffer Manager Buffer Number.
let g:TagmaBufMgrBufNr      = -1

" The Buffer Manager Buffer Name.
let g:TagmaBufMgrBufName    = '_TagmaBufMgr_'

" The help text.
let g:TagmaBufMgrHelpText   = [
    \ '"	<Tab>   l w	Move to the next buffer in the list.',
    \ '"	<S-Tab> h b	Move to the previous buffer in the list.',
    \ '"	D d		Delete the buffer under the cursor.',
    \ '"	<Cr>	O o	Switch to the buffer under the cursor.',
    \ '"	S s		Split then switch to the buffer under the cursor.',
    \ '"	V v		VSplit then switch to the buffer under the cursor.',
    \ '"	P p		Return the the previous window.',
    \ '"	C c		Close the Buffer Manager Window.',
    \ '"	R r		Refresh the Buffer Manager Window.',
    \ '"	? H		Display help text for the Manager.',
    \ '"']

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
function! s:MapPlug(cmd, plug)
    if !hasmapto(a:cmd)
        execute 'noremap <unique> <script> <Plug>' . a:plug . ' :call ' . a:cmd . '<CR>'
    endif
endfunction

call s:MapPlug("<SID>CloseMgr()",           "CloseMgr")
call s:MapPlug("<SID>OpenMgr('M')",         "OpenMgr")
call s:MapPlug("<SID>ShowPopUp()",          "ShowPopUp")
call s:MapPlug("<SID>ToggleMgr('M')",       "ToggleMgr")
call s:MapPlug("<SID>BufCacheRefresh()",    "UpdateMgr")

delfunction s:MapPlug

" Global Key Mappings {{{1
if g:TagmaBufMgrPrefix != ''
    function! s:MapGlobalKey(plug, key)
        if !hasmapto(a:plug)
            execute 'map <silent> <unique> ' .
                        \ g:TagmaBufMgrPrefix . a:key . ' ' . a:plug
        endif
    endfunction

    call s:MapGlobalKey('<Plug>CloseMgr',  'c')
    call s:MapGlobalKey('<Plug>OpenMgr',   'o')
    call s:MapGlobalKey('<Plug>ShowPopUp', 'p')
    call s:MapGlobalKey('<Plug>ToggleMgr', 't')
    call s:MapGlobalKey('<Plug>UpdateMgr', 'u')

    delfunction s:MapGlobalKey
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

" Map Ctrl-[hjkl] keys to switch buffers.
if g:TagmaBufMgrMapChjklbuf
    nnoremap <silent> <C-k>              :call <SID>TabBuffer('P')<CR>
    nnoremap <silent> <C-j>              :call <SID>TabBuffer('N')<CR>
    nnoremap <silent> <C-h>              :call <SID>TabBuffer('P')<CR>
    nnoremap <silent> <C-l>              :call <SID>TabBuffer('N')<CR>

    inoremap <silent> <C-k>         <Esc>:call <SID>TabBuffer('P')<CR>
    inoremap <silent> <C-j>         <Esc>:call <SID>TabBuffer('N')<CR>
    inoremap <silent> <C-h>         <Esc>:call <SID>TabBuffer('P')<CR>
    inoremap <silent> <C-l>         <Esc>:call <SID>TabBuffer('N')<CR>
endif

" Map Ctrl-Tab and Ctrl-Shift-Tab to switch buffers in the current window.
if g:TagmaBufMgrMapCTab
    nnoremap <silent> <C-TAB>           :call <SID>TabBuffer('N')<CR>
    nnoremap <silent> <C-S-TAB>         :call <SID>TabBuffer('P')<CR>

    inoremap <silent> <C-TAB>      <Esc>:call <SID>TabBuffer('N')<CR>
    inoremap <silent> <C-S-TAB>    <Esc>:call <SID>TabBuffer('P')<CR>
endif

" Map Mous Foward/Back to switch buffers in the current window.
if g:TagmaBufMgrMapMouseFB
    nnoremap <silent> <X1Mouse>         :call <SID>TabBuffer('P')<CR>
    nnoremap <silent> <X2Mouse>         :call <SID>TabBuffer('N')<CR>

    inoremap <silent> <X1Mouse>    <Esc>:call <SID>TabBuffer('P')<CR>
    inoremap <silent> <X2Mouse>    <Esc>:call <SID>TabBuffer('N')<CR>
endif

"}}}

" Section: Functions

" Function: s:BufCacheEntry(...)    -- Create/Update Cache Entry {{{1
" Create/Update an entry in the buffer cache for a specific buffer.
" mode is what to do with the entry.
"   A = Add as new. (Also if there is no cache entry for the buffer.)
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
        " Abort if the buffer is not to be listed.
        let l:buf_type = getbufvar(a:buf_nr, '&buftype')
        if !bufexists(a:buf_nr) ||
                    \ (l:buf_type == 'help' && !bufloaded(a:buf_nr)) ||
                    \ (l:buf_type != 'help' && !buflisted(a:buf_nr))
            return 0
        endif

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
        " Current & Loaded Status.
        if l:cache_mode == 'A' || l:cache_mode == 'S'
            let l:cache['cur'] = (a:buf_nr == bufnr('%'))
            let l:cache['load'] = (bufwinnr(a:buf_nr) != -1)
        endif

        " The Buffer Name.
        if l:cache_mode == 'A' || l:cache['noname']
            let l:buf_name = s:FindBufName(a:buf_nr)
            if l:buf_name == '' 
                return 0
            endif
            let l:cache['name'] = substitute(l:buf_name, '\s', '_', 'g')
            let l:cache['noname'] = (l:buf_name == 'No Name' ? 1 : 0)
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

    " Save the cache data to the global cache.
    let g:TagmaBufMgrBufCache[a:buf_nr] = l:cache

    " Create the buffer entry from the cache data.
    call s:BufCacheFormat(a:buf_nr)

    " Return true.
    return 1
endfunction

" Function: s:BufCacheFormat(..)    -- Format Cache Entry {{{1
" Format a cache entry.
" The buffer number to format the entry for is passed in.
function! s:BufCacheFormat(buf_nr)
    " Get the cache for this buffer.
    let l:cache = g:TagmaBufMgrBufCache[a:buf_nr]

    " Format the entry.
    let l:buf_entry = '[' . (l:cache['mod'] ? '+' : '') .
                \ (g:TagmaBufMgrBufferNumbers ? a:buf_nr . ':' : '') .
                \ l:cache['name'] . l:cache['flags'] .
                \ (l:cache['load'] ? '' : '&') .
                \ (l:cache['cur'] ? '!' : '') . ']'

    " Save the formatted entry to the cache.
    let g:TagmaBufMgrBufCache[a:buf_nr]['entry'] = l:buf_entry
endfunction

" Function: s:BufCacheRefresh()     -- Full Cache Refresh {{{1
" Full refresh of the Buffer Cache.
function! s:BufCacheRefresh()
    " Prepare to loop.
    let l:num_buffers = bufnr('$')
    let l:cur_buf = 0

    " Clear the Buffer Cache.
    let g:TagmaBufMgrBufCache = {}

    " Loop over all buffers and build a list.
    while(l:cur_buf < l:num_buffers)
        let l:cur_buf += 1
        let l:buf_type = getbufvar(l:cur_buf, '&buftype')
        if l:cur_buf == g:TagmaBufMgrBufNr || !bufexists(l:cur_buf) ||
                    \ (l:buf_type == 'help' && !bufloaded(l:cur_buf)) ||
                    \ (l:buf_type != 'help' && !buflisted(l:cur_buf))
            continue
        endif

        " Create the Buffer Cache Entry.
        call s:BufCacheEntry('A', l:cur_buf)
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
" If mode is d delete the buffer.
" If mode is m do a quick modification check.
" If mode is u mark the buffer unloaded.
" Otherwise mode is passed to BufCacheEntry.
function! s:BufCacheUpdate(mode, buf_nr)
    " Is the buffer in the cache?
    let l:in_cache = has_key(g:TagmaBufMgrBufCache, a:buf_nr)

    " Do a quick check for modification.
    " Since this will be called often make it as quick as possible.
    if a:mode == 'm'
        let l:buf_mod = getbufvar(a:buf_nr, '&modified')
        if !l:in_cache || (g:TagmaBufMgrBufCache[a:buf_nr]['mod'] == l:buf_mod
                     \ && !g:TagmaBufMgrBufCache[a:buf_nr]['noname'])
            " No change, return.
            return
        endif
        " Update the modification setting and update the entry.
        let g:TagmaBufMgrBufCache[a:buf_nr]['mod'] = l:buf_mod
        call s:BufCacheFormat(a:buf_nr)
    elseif a:buf_nr == g:TagmaBufMgrBufNr
        " Abort if trying to update the Buffer Manager.
        return
    elseif a:mode == 'd'
        " Delete the buffer from the list.
        silent! call remove(g:TagmaBufMgrBufCache, a:buf_nr)
    elseif a:mode == 'u' && l:in_cache
        if g:TagmaBufMgrBufCache[a:buf_nr]['type'] == 'help'
            " Help buffers need to be deleted on unload.
            silent! call remove(g:TagmaBufMgrBufCache, a:buf_nr)
        else
            " Mark the buffer unloaded and update the entry.
            let g:TagmaBufMgrBufCache[a:buf_nr]['load'] = 0
            call s:BufCacheFormat(a:buf_nr)
        endif
    else
        " Update the entry.
        " If there was no change just return.
        if !s:BufCacheEntry(a:mode, a:buf_nr)
            return
        endif
    endif

    " If checking for modification don't update the PopUp.
    if a:mode != 'm' && g:TagmaBufMgrPopUp
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
        if len(l:tip_line) == 0
            return 'Buffer not loaded.'
        endif
        let l:buf_nr = strpart(l:tip_line[0], 0, v:beval_col)
        let l:buf_nr = substitute(l:buf_nr, '.*\[+\?\(\d\+\)[^\[]\+$', '\1', '')
    endif
    let l:buf_nr = l:buf_nr + 0

    " If the buffer is not in the cache just return.
    if !has_key(g:TagmaBufMgrBufCache, l:buf_nr)
        return ''
    endif

    " Get the information for the Tool Tip.
    let l:buf_name = g:TagmaBufMgrBufCache[l:buf_nr]['name']
    let l:buf_type = getbufvar(l:buf_nr, '&filetype')
    let l:buf_file = expand('#' . l:buf_nr)
    if l:buf_file != ''
        let l:buf_file = fnamemodify(l:buf_file, ':p:~')
    endif
    let l:buf_fold = getbufvar(l:buf_nr, '&foldmethod')
    if l:buf_fold == 'marker'
        let l:buf_fold .= '] Fold Marker: [' . getbufvar(l:buf_nr, '&foldmarker')
    endif

    " Build the Tool Tip as a list.
    let l:tool_tip = [
        \ 'Buffer [' . l:buf_name . '] # ' . l:buf_nr .
            \ (l:buf_nr == bufnr('%') ? ' (Current)' : ''),
        \ 'File Name: ' . (l:buf_file == '' ? 'N/A' : l:buf_file),
        \ 'Type: [' . (l:buf_type == '' ? 'N/A' : l:buf_type) . '] ' .
            \ 'Format: [' . getbufvar(l:buf_nr, '&fileformat') . ']',
        \ 'Fold Method: [' . l:buf_fold . ']',
        \ (getbufvar(l:buf_nr, '&modified') ? 'Modified!' : 'Not Modified') . ' - ' .
            \ (getbufvar(l:buf_nr, '&readonly') ? 'Readonly!' : 'Writeable'),
        \ ]

    " Return the Tool Tip.
    return join(l:tool_tip, has('balloon_multiline') ? "\n" : ' ')
endfunction

" Function: s:CloseMgr()            -- Close Manager Window {{{1
function! s:CloseMgr()
    " See if the Manager Window is visible.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1
        return
    endif

    " If not already in the Manager Window save the current and previous
    " windows then switch to the Manager Window.
    if winnr() != l:mgr_winnr
        let l:prev_win = [winnr('#'), winnr()]
        execute l:mgr_winnr . 'wincmd w'
        wincmd c
        execute l:prev_win[0] . 'wincmd w'
        execute l:prev_win[1] . 'wincmd w'
    else
        wincmd c
    endif
endfunction

" Function: s:CreateMgrWin()        -- Create Manager Window {{{1
" Create the Manager Window in the desired location.
" Controlled by the setting g:TagmaBufMgrLocation.
function! s:CreateMgrWin()
    " Set the orientation and create the Manager Window.
    let l:cmd_prefix = ''
    let g:TagmaBufMgrOrient = 'H'
    if g:TagmaBufMgrLocation == 'B' || g:TagmaBufMgrLastLine
        let l:cmd_prefix = 'botright'
    elseif g:TagmaBufMgrLocation == 'T'
        let l:cmd_prefix = 'topleft'
    else
        let g:TagmaBufMgrOrient = 'V'
        if g:TagmaBufMgrLocation == 'L'
            let l:cmd_prefix = 'topleft'
        elseif g:TagmaBufMgrLocation == 'R'
            let l:cmd_prefix = 'botright'
        endif
    endif

    " Save the eventignore setting then disable all events.
    " Events were causing strange behavior at times.
    " In investigated how Tagmbar works and found this is how it avoided the
    " same issues.
    let l:eventignore_save = &eventignore
    set eventignore=all
    execute 'silent! keepalt ' . l:cmd_prefix . ' split ' . g:TagmaBufMgrBufName
    let &eventignore = l:eventignore_save

    " Lock the window size if not floating.
    if g:TagmaBufMgrLocation != 'F'
        setlocal winfixheight
        setlocal winfixwidth
    endif

    " Change the status line.
    let &l:stl=g:TagmaBufMgrStatusLine

    " Save and set &laststatus.
    if g:TagmaBufMgrLastLine && &laststatus != 0
        let g:TagmaBufMgrLastStatusSave = &laststatus
        set laststatus=0
        " Restore &laststatus when the buffer is unloaded.
        autocmd BufUnload <buffer> let &laststatus=g:TagmaBufMgrLastStatusSave
    endif

    " This gets lost for some reason.
    setlocal nobuflisted
endfunction

" Function: s:DeleteBuf()           -- Delete Buffer {{{1
" Delete a Buffer when the user requests.
function! s:DeleteBuf()
    " Determine the buffer to delete.
    let l:buf_nr = s:GetBufNr()
    if l:buf_nr != ''
        " Delete the buffer.
        execute 'bd ' l:buf_nr
    endif
endfunction

" Function: s:DisplayHelp()         -- Display Manager Help {{{1
" Display the Buffer Manager help text.
function! s:DisplayHelp()
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1 || winnr() != l:mgr_winnr
        return
    endif

    " Display the text and resize.
    let l:cur_pos = getpos('.')
    setlocal modifiable
    call append(0, g:TagmaBufMgrHelpText)
    setlocal nomodifiable
    if g:TagmaBufMgrOrient == 'H'
        execute 'resize ' . line('$')
    endif
    normal! gg
    let l:cur_pos[1] += len(g:TagmaBufMgrHelpText)
    call setpos('.', l:cur_pos)
endfunction

" Function: s:DisplayList()         -- Display Buffer List {{{1
" Display the buffer list in the Manager Window.
function! s:DisplayList()
    " If the Manager is not visible nothing to do.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1 
        return
    endif

    " If not already in the Manager Window save the current and previous
    " windows then switch to the Manager Window.
    if winnr() != l:mgr_winnr
        let l:prev_win = [winnr('#'), winnr()]
        execute l:mgr_winnr . 'wincmd w'
    endif

    " Generate the list from the cache.
    let l:buf_list = map(sort(keys(g:TagmaBufMgrBufCache), "s:SortNumeric"),
                        \ "g:TagmaBufMgrBufCache[v:val]['entry']")

    " Save the " register and cursor position.
    let l:save_quote = @"
    let l:cur_pos = getpos('.')

    " Clear the current buffer list.
    setlocal modifiable
    silent! normal! ggdG

    "  Write, Format, Resize...
    if g:TagmaBufMgrOrient == 'H'
        call setline(1, join(l:buf_list))
        execute 'setlocal textwidth=' . &columns
        silent! normal! gqqgg
        execute 'resize ' . line('$')
    else
        call append(0, l:buf_list)
        normal! Gddgg
        if g:TagmaBufMgrWidth > 0 && g:TagmaBufMgrLocation != 'F'
            execute 'vertical resize ' . g:TagmaBufMgrWidth
        endif
    endif
    setlocal nomodifiable

    " Restore the " register and cursor position.
    let @" = l:save_quote
    call setpos('.', l:cur_pos)

    " If we switched windows go back.
    if exists('l:prev_win')
        execute l:prev_win[0] . 'wincmd w'
        execute l:prev_win[1] . 'wincmd w'
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
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal foldcolumn=0
    setlocal formatoptions=
    setlocal matchpairs=
    setlocal nomodifiable
    setlocal nonumber
    setlocal noswapfile
    setlocal nowrap

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

    " Set the buffer commands.
    call s:InitMgrcmds()

    " Balloon/Tool Tips settings.
    if has('balloon_eval')
        setlocal balloonexpr=BufMgrToolTips()
        setlocal ballooneval
    endif

    " Note that the initialization has been performed.
    let b:TagmaBufMgrInit = 1
endfunction

" Function: s:InitMgrcmds()         -- Initialize Manager Commands {{{1
" Replaces normal commands so they act on the previous window instead of the
" Manager Window.
function! s:InitMgrcmds()
    " Don't switch buffers in the Manager Window.
    cnoreabbrev <buffer> bn                     wincmd<Space>p<CR>:bn
    cnoreabbrev <buffer> bnext                  wincmd<Space>p<CR>:bnext
    cnoreabbrev <buffer> bp                     wincmd<Space>p<CR>:bp
    cnoreabbrev <buffer> bprev                  wincmd<Space>p<CR>:bprev

    " Don't open files in the Manager Window.
    cnoreabbrev <buffer> e                      wincmd<Space>p<CR>:e
    cnoreabbrev <buffer> edit                   wincmd<Space>p<CR>:edit
    cnoreabbrev <buffer> ene                    wincmd<Space>p<CR>:ene
    cnoreabbrev <buffer> enew                   wincmd<Space>p<CR>:enew
    cnoreabbrev <buffer> fin                    wincmd<Space>p<CR>:fin
    cnoreabbrev <buffer> find                   wincmd<Space>p<CR>:find

    " Don't write files in the Manager Window.
    cnoreabbrev <buffer> w                      wincmd<Space>p<CR>:w
    cnoreabbrev <buffer> write                  wincmd<Space>p<CR>:write
endfunction

" Function: s:InitMgrKeys()         -- Initialize Manager Keys Maps {{{1
function! s:InitMgrKeys()
    " Nagivate between buffer entries.
    call s:MapBufKeys(['l', 'w', '<TAB>'],      ":call search('\[', 'w')")
    call s:MapBufKeys(['h', 'b', '<S-TAB>'],    ":call search('\[', 'bw')")

    " Delete buffer entres.
    call s:MapBufKeys(['D', 'd'],               ":call <SID>DeleteBuf()")

    " Open buffer entries.
    call s:MapBufKeys(['O', 'o', '<CR>'],       ":call <SID>SwitchBuf('n')")
    call s:MapBufKeys(['S', 's'],               ":call <SID>SwitchBuf('S')")
    call s:MapBufKeys(['V', 'v'],               ":call <SID>SwitchBuf('V')")

    " Return to the previous window.
    call s:MapBufKeys(['P', 'p'],               ":wincmd p ")

    " Close the Buffer Manager.
    call s:MapBufKeys(['C', 'c'],               ":call <SID>CloseMgr()")

    " Refresh the Buffer Manager.
    call s:MapBufKeys(['R', 'r'],               ":call <SID>BufCacheRefresh()")

    " Help.
    call s:MapBufKeys(['?', 'H'],               ":call <SID>DisplayHelp()")

    " Manager Buffer Specific Menu.
    if has('menu')
        anoremenu <silent>  ]BufMgr.&Close\ Mgr     :call <SID>CloseMgr()<CR>
        anoremenu <silent>  ]BufMgr.&Refresh\ Mgr   :call <SID>BufCacheRefresh()<CR>
        anoremenu           ]BufMgr.-Separator-     :
        anoremenu <silent>  ]BufMgr.Switch&To       :call <SID>SwitchBuf('N')<CR>
        anoremenu <silent>  ]BufMgr.&Split          :call <SID>SwitchBuf('S')<CR>
        anoremenu <silent>  ]BufMgr.&Vertical       :call <SID>SwitchBuf('V')<CR>
        anoremenu <silent>  ]BufMgr.&Delete         :call <SID>DeleteBuf()<CR>
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
    syn match       TagmaBufMgrPlain        '\[[^\]]\+\]'
    syn match       TagmaBufMgrActive       '\[[^\]]\+!\]'
    syn match       TagmaBufMgrUnLoaded     '\[[^\]]\+&\]'
    syn match       TagmaBufMgrChanged      '\[+[^\]]\+\]'
    syn match       TagmaBufMgrChgAct       '\[+[^\]]\+!\]'
    syn match       TagmaBufMgrHelp         '\[[^\]]\+?\]'
    syn match       TagmaBufMgrQFoLL        '\[[^\]]\+\$\]'
    syn match       TagmaBufMgrHelpText     '^".*$'

    hi def link     TagmaBufMgrPlain        Comment
    hi def link     TagmaBufMgrActive       Identifier
    hi def link     TagmaBufMgrChanged      String
    hi def link     TagmaBufMgrChgAct       Error
    hi def link     TagmaBufMgrHelp         Type
    hi def link     TagmaBufMgrQFoLL        Special
    hi def link     TagmaBufMgrUnloaded     Statement
    hi def link     TagmaBufMgrHelpText     Comment
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
    autocmd BufHidden       *   call s:BufCacheUpdate('u', expand('<abuf>'))
    autocmd VimResized      *   call s:DisplayList()

    " Check for modification changes.
    autocmd BufWritePost,CursorHold,CursorHoldI *
                              \ call s:BufCacheUpdate('m', bufnr('%'))

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
    if l:mgr_winnr != -1
        if winbufnr(2) == -1
            if g:TagmaBufMgrLastWindow
                qall
            else
                execute 'resize ' . &lines
                new
                call s:CloseMgr()
                call s:OpenMgr('A')
            endif
        endif
    endif
endfunction

" Function: s:MapBufKeys(...)       -- Map Buffer Keys {{{1
" Maps a list of keys to a command for the current buffer.
function! s:MapBufKeys(keys, cmd)
    for l:key in a:keys
        execute 'nnoremap <buffer> <silent> ' . l:key . ' ' . a:cmd . '<CR>'
    endfor
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

    " Create/Switch the buffer.
    if l:winnr == -1
        " Create/Switch to the buffer and window.
        call s:CreateMgrWin()
    else
        " Switch to the window.
        execute l:winnr . 'wincmd w'
    endif

    " Save the Manager Buffer # for later use.
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
" Create the PopUp Menu additions for switching buffers from the Cache.
function! s:PopUpMenu()
    " Clear the old PopUp Menu.
    silent! unmenu PopUp.SwitchTo

    " Add the buffer list to the PopUp Menu.
    for l:cur_buf in sort(keys(g:TagmaBufMgrBufCache), "s:SortNumeric")
        let l:buf_name = g:TagmaBufMgrBufCache[l:cur_buf]['name']
        execute 'nnoremenu <silent> PopUp.SwitchTo.' .
                    \ escape(l:buf_name . ' (' . l:cur_buf . ')', '. \') .
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

" Function: s:SortNumeric(i1, i2)   -- Numeric sort function. {{{1
function! s:SortNumeric(i1, i2)
    let l:i1 = a:i1 + 0
    let l:i2 = a:i2 + 0
    return l:i1 == l:i2 ? 0 : l:i1 > l:i2 ? 1 : -1
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
    wincmd p

    " Switch to the buffer according to the mode.
    let l:cmd_prefix = ''
    if a:mode == 'S'
        let l:cmd_prefix = 'split +'
    elseif a:mode == 'V'
        let l:cmd_prefix = 'vsplit +'
    endif
        execute l:cmd_prefix . 'b' . l:buf_nr

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
    execute l:dir_func
    if bufnr('%') == g:TagmaBufMgrBufNr
        execute l:dir_func
    endif
endfunction

" Function: s:ToggleMgr(...)        -- Toggle Manager Window {{{1
" The mode is passed to OpenMgr.
function! s:ToggleMgr(mode)
    " See if the Manager Window is visible.
    let l:mgr_winnr = bufwinnr(g:TagmaBufMgrBufNr)
    if l:mgr_winnr == -1
        call s:OpenMgr(a:mode)
    else
        call s:CloseMgr()
    endif
endfunction
