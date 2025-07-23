#!/bin/bash

# Build Docker images for MCP server templates

set -e

# Configuration
REGISTRY=${MCP_IMAGE_REGISTRY:-"ghcr.io/data-everything"}
TEMPLATES_REPO=${MCP_TEMPLATES_REPO:-"https://github.com/Data-Everything/mcp-server-templates.git"}
BUILD_DIR=${BUILD_DIR:-"/tmp/mcp-build"}

echo "🏗️  Building MCP Server Template Images"
echo "Registry: $REGISTRY"
echo "Templates Repo: $TEMPLATES_REPO"
echo "Build Directory: $BUILD_DIR"

# Clean up and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone templates repository
echo "📥 Cloning templates repository..."
git clone "$TEMPLATES_REPO" templates
cd templates

# Build each template
for template_dir in */; do
    if [[ -d "$template_dir" && -f "${template_dir}Dockerfile" ]]; then
        template_name=$(basename "$template_dir")
        image_name="${REGISTRY}/mcp-${template_name}:latest"
        
        echo "🐳 Building image for template: $template_name"
        echo "   Image: $image_name"
        
        cd "$template_dir"
        
        # Build Docker image
        docker build -t "$image_name" .
        
        # Tag with latest and version if available
        if [[ -f "template.json" ]]; then
            version=$(jq -r '.version // "latest"' template.json)
            if [[ "$version" != "latest" && "$version" != "null" ]]; then
                version_image="${REGISTRY}/mcp-${template_name}:${version}"
                docker tag "$image_name" "$version_image"
                echo "   Also tagged as: $version_image"
            fi
        fi
        
        echo "✅ Built $image_name"
        cd ..
    else
        echo "⏭️  Skipping $template_dir (no Dockerfile found)"
    fi
done

echo "🎉 All template images built successfully!"
echo ""
echo "To push images to registry, run:"
echo "  docker push $REGISTRY/mcp-*"
echo ""
echo "To build for a specific template only:"
echo "  $0 <template-name>"
