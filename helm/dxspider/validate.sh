#!/bin/bash
# validate.sh - Quick validation script for DXSpider Helm chart
# Usage: ./validate.sh

set -e

CHART_DIR="."
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "DXSpider Helm Chart Validation"
echo "========================================="
echo ""

# Function to print success
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    error "Helm is not installed. Please install Helm 3.x"
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi
success "Helm is installed"

# Check helm version
HELM_VERSION=$(helm version --short | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
success "Helm version: $HELM_VERSION"

# Check if Chart.yaml exists
if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
    error "Chart.yaml not found"
    exit 1
fi
success "Chart.yaml found"

# Check if values.yaml exists
if [ ! -f "$CHART_DIR/values.yaml" ]; then
    error "values.yaml not found"
    exit 1
fi
success "values.yaml found"

# Check if templates directory exists
if [ ! -d "$CHART_DIR/templates" ]; then
    error "templates/ directory not found"
    exit 1
fi
success "templates/ directory found"

# Count template files
TEMPLATE_COUNT=$(find "$CHART_DIR/templates" -type f -name "*.yaml" -o -name "*.tpl" -o -name "*.txt" | wc -l)
success "Found $TEMPLATE_COUNT template files"

# Lint the chart
echo ""
echo "Running helm lint..."
if helm lint "$CHART_DIR"; then
    success "Helm lint passed"
else
    error "Helm lint failed"
    exit 1
fi

# Template the chart
echo ""
echo "Testing template rendering..."
if helm template test "$CHART_DIR" --namespace dxspider-test > /dev/null 2>&1; then
    success "Template rendering successful"
else
    error "Template rendering failed"
    exit 1
fi

# Template with production values
echo ""
echo "Testing template rendering with production values..."
if helm template test "$CHART_DIR" --namespace dxspider-test -f "$CHART_DIR/values-production.yaml" > /dev/null 2>&1; then
    success "Production template rendering successful"
else
    error "Production template rendering failed"
    exit 1
fi

# Dry run
echo ""
echo "Testing dry-run installation..."
if helm install test "$CHART_DIR" --namespace dxspider-test --dry-run > /dev/null 2>&1; then
    success "Dry-run installation successful"
else
    error "Dry-run installation failed"
    exit 1
fi

# Check for required files
echo ""
echo "Checking for required files..."
REQUIRED_FILES=(
    "Chart.yaml"
    "values.yaml"
    "values-production.yaml"
    "README.md"
    ".helmignore"
    "templates/_helpers.tpl"
    "templates/statefulset.yaml"
    "templates/service.yaml"
    "templates/configmap.yaml"
    "templates/secret.yaml"
    "templates/NOTES.txt"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$CHART_DIR/$file" ]; then
        success "$file exists"
    else
        warning "$file not found"
    fi
done

# Summary
echo ""
echo "========================================="
echo -e "${GREEN}Validation Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review the README.md for installation instructions"
echo "2. Customize values-example.yaml for your environment"
echo "3. Test installation with 'make install' or follow INSTALL.md"
echo ""
echo "For more information, see:"
echo "  - README.md: Comprehensive documentation"
echo "  - INSTALL.md: Quick installation guide"
echo "  - TESTING.md: Testing procedures"
echo ""
