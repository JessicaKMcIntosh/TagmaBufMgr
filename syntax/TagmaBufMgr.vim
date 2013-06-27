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
