#!/bin/bash


# Get the directory of the current script
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Source common.sh from the same directory
source "${SCRIPT_DIR}/lib/common.sh"


#########################################
# Canvas REST API bash wrapper          #
#########################################

# Help / usage message
function usage() {
    echo "Usage: context <command> [arguments]"
    echo "Commands:"
    echo "  set <url>        Set the context URL"
    echo "  tree             Get the context tree"
    echo "  path             Get the current context path"
    echo "  paths            Get all available context paths"
    echo "  url              Get the current context URL"
    echo "  bitmaps          Get the context bitmaps"
    echo "  list             List all documents for the given context"
    echo "  list <abstr>     List all documents for the given context of a given abstraction"
    echo ""
}

# Main context function
function context() {

    local res;

    # Check for arguments
    if [[ $# -eq 0 ]]; then
        echo "Error: missing argument"
        usage
        return 1
    fi

    # Parse command and arguments
    local command="$1"
    shift

    case "$command" in
    set)
        # Parse URL argument
        if [[ $# -ne 1 ]]; then
            echo "Error: invalid arguments for 'set' command"
            echo "Usage: context set <url>"
            return 1
        fi

        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        local url="$1"
        res=$(canvas_http_post "/context/url" "{\"url\": \"$url\"}")
        if echo "$res" | jq .status | grep -q "error"; then
            echo "Error: failed to set context URL"
            echo "Response: $res"
            return 1
        fi

        echo "$res" | jq -r '.status + " | " + .message + ": " + .payload'
        ;;

    tree)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        canvas_http_get "/context/tree" | jq .payload | jq .
        ;;

    path)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        canvas_http_get "/context/path" | jq '.payload' | sed 's/"//g'
        ;;

    paths)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        canvas_http_get "/context/paths" | jq '.payload'
        ;;

    url)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        canvas_http_get "/context/url" | jq '.payload'
        ;;

    bitmaps)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        canvas_http_get "/context/bitmaps" | jq '.payload'
        ;;
    insert)
        # Parse path argument
        if [[ $# -ne 1 ]]; then
            echo "Error: invalid arguments for 'add' command"
            echo "Usage: context add <path>"
            return 1
        fi

        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        # TODO: send API request to add file or folder to context
        ;;

    list)
        if ! canvas_api_reachable; then
            echo "Error: Canvas API endpoint not reachable on $CANVAS_HOST:$CANVAS_PORT"
            return 1
        fi

        # Parse optional document type argument
        if [[ $# -eq 0 ]]; then
            canvas_http_get "/context/documents" | jq .
        else
            case "$1" in
            notes)
                canvas_http_get "/context/documents/notes" | jq .
                ;;
            tabs)
                canvas_http_get "/context/documents/tabs" | jq .
                ;;
            todo)
                canvas_http_get "/context/documents/todo" | jq .
                ;;
            files)
                canvas_http_get "/context/documents/files" | jq .
                ;;

            *)
                echo "Error: untested document type '$1'"
                echo "Usage: context list [notes|tabs|todo|files]"
                # Temporary
                canvas_http_get "/context/documents/$1" | jq .
                return 1
                ;;
            esac
        fi
        ;;

    *)
        echo "Error: unknown command '$command'"
        usage
        return 1
        ;;
    esac
}

# Add context URL to prompt
if canvas_api_reachable; then
    # Add the initial PS1 prompt
    export PS1="[\$(context path)] $PS1";
fi;

