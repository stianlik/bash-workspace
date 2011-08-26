function! Bws_import()
    silent execute "!bws _call export_workspace_to_vim &" | redraw!
    source ~/.bash-workspace/vim
endfunction

function! Bws_cd(name)
    call Bws_import()
    let var_name = "_bws_link_" . a:name
    if !exists("g:{var_name}")
        echo a:name "not found"
        return
    endif
    cd `=g:{var_name}`
    pwd
endfunction
