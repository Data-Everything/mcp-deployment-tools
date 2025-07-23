#!/bin/bash

# MCP Server Management Script
# Manage deployed MCP servers (start, stop, restart, logs, status)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
ACTION=""
SERVER_NAME=""
DEPLOYMENT_TYPE="docker"
NAMESPACE="mcp-platform"

usage() {
    echo "Usage: $0 ACTION [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  start                   Start a server"
    echo "  stop                    Stop a server"
    echo "  restart                 Restart a server"
    echo "  status                  Show server status"
    echo "  logs                    Show server logs"
    echo "  list                    List all servers"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME         Server name (required for most actions)"
    echo "  -t, --type TYPE         Deployment type: docker, kubernetes (default: docker)"
    echo "  --namespace NAME        Kubernetes namespace (default: mcp-platform)"
    echo "  -f, --follow            Follow logs (for logs action)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 status --name my-server"
    echo "  $0 logs --name my-server --follow"
    echo "  $0 restart --name my-server --type kubernetes"
}

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

ACTION="$1"
shift

FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SERVER_NAME="$2"
            shift 2
            ;;
        -t|--type)
            DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -f|--follow)
            FOLLOW_LOGS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate server name for actions that require it
case "$ACTION" in
    "start"|"stop"|"restart"|"status"|"logs")
        if [ -z "$SERVER_NAME" ]; then
            echo "Error: Server name is required for action: $ACTION"
            usage
            exit 1
        fi
        ;;
esac

echo "🔧 Managing MCP Server: $ACTION"
if [ -n "$SERVER_NAME" ]; then
    echo "   Server: $SERVER_NAME"
fi
echo "   Type: $DEPLOYMENT_TYPE"
echo ""

case "$DEPLOYMENT_TYPE" in
    "docker")
        case "$ACTION" in
            "start")
                docker start "$SERVER_NAME"
                echo "✅ Server started: $SERVER_NAME"
                ;;
            "stop")
                docker stop "$SERVER_NAME"
                echo "✅ Server stopped: $SERVER_NAME"
                ;;
            "restart")
                docker restart "$SERVER_NAME"
                echo "✅ Server restarted: $SERVER_NAME"
                ;;
            "status")
                echo "📊 Server status:"
                docker ps -a --filter "name=$SERVER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                ;;
            "logs")
                if [ "$FOLLOW_LOGS" = true ]; then
                    docker logs -f "$SERVER_NAME"
                else
                    docker logs "$SERVER_NAME"
                fi
                ;;
            "list")
                echo "📋 All MCP servers:"
                docker ps -a --filter "label=mcp-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" || \
                docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" | grep -E "(mcp-|MCP)" || \
                echo "No MCP servers found"
                ;;
            *)
                echo "Error: Unknown action: $ACTION"
                usage
                exit 1
                ;;
        esac
        ;;
        
    "kubernetes")
        case "$ACTION" in
            "start")
                kubectl scale deployment "$SERVER_NAME" --replicas=1 -n "$NAMESPACE"
                echo "✅ Server started: $SERVER_NAME"
                ;;
            "stop")
                kubectl scale deployment "$SERVER_NAME" --replicas=0 -n "$NAMESPACE"
                echo "✅ Server stopped: $SERVER_NAME"
                ;;
            "restart")
                kubectl rollout restart deployment "$SERVER_NAME" -n "$NAMESPACE"
                echo "✅ Server restarted: $SERVER_NAME"
                ;;
            "status")
                echo "📊 Server status:"
                kubectl get deployment "$SERVER_NAME" -n "$NAMESPACE" -o wide
                echo ""
                kubectl get pods -l app="$SERVER_NAME" -n "$NAMESPACE"
                ;;
            "logs")
                if [ "$FOLLOW_LOGS" = true ]; then
                    kubectl logs -l app="$SERVER_NAME" -n "$NAMESPACE" -f
                else
                    kubectl logs -l app="$SERVER_NAME" -n "$NAMESPACE" --tail=100
                fi
                ;;
            "list")
                echo "📋 All MCP servers in namespace $NAMESPACE:"
                kubectl get deployments -n "$NAMESPACE" -o wide
                ;;
            *)
                echo "Error: Unknown action: $ACTION"
                usage
                exit 1
                ;;
        esac
        ;;
        
    *)
        echo "Error: Unknown deployment type: $DEPLOYMENT_TYPE"
        exit 1
        ;;
esac
