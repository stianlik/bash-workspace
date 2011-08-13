source ~/.bash-workspace/vim

function! Bws_cd(name)
    let var_name = "_bws_link_" . a:name
    cd `=g:{var_name}`
endfunction
