function proxyon
    set proxy 'socks5://127.0.0.1:'
    if test (count $argv) -eq 1
        set proxy {$proxy}$argv[1]
    else
        set proxy {$proxy}1081
    end

    set PROXY_ENV 'all_proxy http_proxy https_proxy ftp_proxy'\
        'ALL_PROXY HTTP_PROXY HTTPS_PROXY FTP_PROXY'
    for e in (echo $PROXY_ENV | sed 's/ /\n/g')
        export $e=$proxy
    end
    export no_proxy='localhost,127.0.0.1,localaddress'
end

function proxyoff
    set PROXY_ENV 'all_proxy http_proxy https_proxy ftp_proxy'\
        'ALL_PROXY HTTP_PROXY HTTPS_PROXY FTP_PROXY'
    for e in (echo $PROXY_ENV | sed 's/ /\n/g')
        set -e $e
    end
    set -e no_proxy
end

function pppex
    echo 'killing NetworkManager...'
    sudo systemctl stop NetworkManager
    echo 'killing wpa_supplicant'
    sudo pkill wpa_supplicant
    echo 'start pppoe-connect...'
    sudo pppoe-connect
end
