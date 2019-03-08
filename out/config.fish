alias p "proxychains -q"
set fish_greeting
set -gx PATH ~/.local/bin $PATH
set -x EDITOR vim
set -x GOPATH $HOME/go
alias s "sh -c 'sslocal -c $HOME/ss/jd_ss.json 1> /tmp/ss.log 2>&1 & proxychains -f $HOME/ss/2080.conf python $HOME/ss/shadowsocksr/shadowsocks/local.py -c $HOME/.config/ssr/USING.JSON 1> /tmp/ssr.log 2>&1'"

