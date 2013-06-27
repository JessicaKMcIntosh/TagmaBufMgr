" =============================================================================
" File:         TagmaBufMgr.vim (Syntax)
" Last Changed: Thu Jun 27 12:52 PM 2013 EDT
" Maintainer:   Jessica K McIntosh AT Gmail...
" License:      Public Domain
"
" Description:  Syntax highlighting for TagmaBufMgr
" =============================================================================

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

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

let b:current_syntax = "TagmaBufMgr"

let &cpo = s:cpo_save
unlet s:cpo_save
