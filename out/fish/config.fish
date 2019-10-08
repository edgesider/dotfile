alias pc "proxychains"
alias po "proxyon"
alias pf "proxyoff"
set fish_greeting
set -gx PATH ~/.local/bin $PATH
set -x EDITOR vim
set -x GOPATH $HOME/go

set -x DLD $HOME/Downloads/
set -x DCU $HOME/Documents/

alias s "sh -c 'sslocal -c $HOME/ss/jd_ss.json 1> /tmp/ss.log 2>&1 & proxychains -f $HOME/ss/2080.conf python $HOME/ss/shadowsocksr/shadowsocks/local.py -c $HOME/.config/ssr/USING.JSON 1> /tmp/ssr.log 2>&1'"
alias dl "prevd -l"
alias dp prevd
alias dn nextd

complete -c v2 -x -a '(ls /home/kai/tools/v2ray/config | grep .json | string replace .json "")' --condition '__fish_seen_subcommand_from start'
complete -c v2 -x -a start --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a restart --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a stop --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a status --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a stat --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a list --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a ls --condition '__fish_v2_no_subcommand'
complete -c v2 -x -a test --condition '__fish_v2_no_subcommand'

function __fish_v2_no_subcommand
    for i in (commandline -cop)
        if contains -- $i start status stop restart stat list ls test
            return 1
        end
    end
    return 0
end
