# luoking-box shell integration
# This file provides shell functions for luoking-box proxy management
# Source this file once (or add to ~/.bashrc/~/.zshrc) to enable direct usage

_luoking_box_enable_session() {
    local proxy_url
    proxy_url=$(/usr/bin/luoking-box enable session 2>/dev/null)
    
    if [ -z "$proxy_url" ] || [[ ! "$proxy_url" =~ ^http:// ]]; then
        echo "Error: Failed to get proxy configuration" >&2
        return 1
    fi
    
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export all_proxy="$proxy_url"
    export ALL_PROXY="$proxy_url"
    
    echo "[proxy] Shell proxy enabled: $proxy_url"
}

_luoking_box_clear_session() {
    unset http_proxy https_proxy all_proxy
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    
    /usr/bin/luoking-box clear session >/dev/null 2>&1
    echo "[noproxy] Shell proxy cleared."
}

# Override luoking-box command with wrapper function
luoking-box() {
    case "${1:-}" in
        enable)
            shift
            if [ $# -eq 0 ]; then
                /usr/bin/luoking-box enable "$@"
                return
            fi
            
            # Check if session is in the targets
            local has_session=false
            for target in "$@"; do
                if [ "$target" = "session" ]; then
                    has_session=true
                    break
                fi
            done
            
            if [ "$has_session" = true ]; then
                # Handle session separately
                local other_targets=()
                for target in "$@"; do
                    if [ "$target" != "session" ]; then
                        other_targets+=("$target")
                    fi
                done
                
                # Enable session proxy in current shell
                _luoking_box_enable_session
                
                # Handle other targets
                if [ ${#other_targets[@]} -gt 0 ]; then
                    /usr/bin/luoking-box enable "${other_targets[@]}"
                fi
            else
                # No session target, just call original command
                /usr/bin/luoking-box enable "$@"
            fi
            ;;
        clear)
            shift
            if [ $# -eq 0 ]; then
                /usr/bin/luoking-box clear "$@"
                return
            fi
            
            # Check if session is in the targets
            local has_session=false
            for target in "$@"; do
                if [ "$target" = "session" ]; then
                    has_session=true
                    break
                fi
            done
            
            if [ "$has_session" = true ]; then
                # Handle session separately
                local other_targets=()
                for target in "$@"; do
                    if [ "$target" != "session" ]; then
                        other_targets+=("$target")
                    fi
                done
                
                # Clear session proxy in current shell
                _luoking_box_clear_session
                
                # Handle other targets
                if [ ${#other_targets[@]} -gt 0 ]; then
                    /usr/bin/luoking-box clear "${other_targets[@]}"
                fi
            else
                # No session target, just call original command
                /usr/bin/luoking-box clear "$@"
            fi
            ;;
        *)
            # All other commands pass through to original
            /usr/bin/luoking-box "$@"
            ;;
    esac
}

