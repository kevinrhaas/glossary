#!/bin/bash
# 03-transfer-and-build.sh
# Transfer application files to EC2 and build locally

set -e

# Source shell configuration to get okta-aws function
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
elif [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Configuration
ENVIRONMENT=${1:-"prod"}  # Default to prod, can specify test
PROJECT_NAME="glossary"
KEY_PATH="$HOME/.ssh/pentaho+_se_keypair.pem"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Invalid environment name. Use alphanumeric characters, hyphens, or underscores"
    echo "Usage: $0 [environment]"
    echo "Examples:"
    echo "  $0 prod"
    echo "  $0 test"
    echo "  $0 dev"
    echo "  $0 staging"
    exit 1
fi

echo "📦 Transferring files and building on EC2..."
echo "Environment: ${ENVIRONMENT}"
echo ""

# Determine project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Pre-flight checks - verify required files exist
echo "🔍 Pre-flight checks..."
REQUIRED_FILES=("app.py" "requirements.txt" "Dockerfile" ".env")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${PROJECT_ROOT}/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    echo "Please ensure all required files exist before running this script"
    exit 1
fi

echo "✅ All required files found"

# Check if instance info exists
if [ ! -f "${SCRIPT_DIR}/instance-info-${ENVIRONMENT}.env" ]; then
    echo "❌ Instance info file not found: instance-info-${ENVIRONMENT}.env"
    echo "Please run ./01-create-ec2-instance.sh ${ENVIRONMENT} first"
    exit 1
fi

# Source instance info
source "${SCRIPT_DIR}/instance-info-${ENVIRONMENT}.env"

# Use Elastic IP if available, otherwise Public IP, otherwise Private IP
if [ -n "${ELASTIC_IP:-}" ] && [ "${ELASTIC_IP}" != "null" ]; then
    TARGET_IP=${ELASTIC_IP}
    ACCESS_TYPE="Elastic IP"
elif [ -n "${PUBLIC_IP:-}" ] && [ "${PUBLIC_IP}" != "null" ]; then
    TARGET_IP=${PUBLIC_IP}
    ACCESS_TYPE="Public IP"
else
    TARGET_IP=${PRIVATE_IP}
    ACCESS_TYPE="Private IP (requires VPN/network access)"
fi

echo "🎯 Target instance: ${INSTANCE_ID} (${TARGET_IP}) via ${ACCESS_TYPE}"

# Check if instance is running
echo "🔍 Checking instance status..."
INSTANCE_STATE=$(okta-aws khaas ec2 describe-instances \
    --region ${REGION} \
    --instance-ids ${INSTANCE_ID} \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ Instance is not running (state: $INSTANCE_STATE)"
    exit 1
fi

echo "✅ Instance is running"

# Wait for SSH to be available (user-data script may be running)
echo "🔑 Waiting for SSH access (user-data script may still be running)..."
echo "    This can take 3-5 minutes for a fresh instance..."
SSH_READY=false
for i in {1..12}; do  # Try for up to 6 minutes
    echo -n "   Attempt $i/12: "
    if ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ec2-user@${TARGET_IP} "echo 'SSH ready'" >/dev/null 2>&1; then
        SSH_READY=true
        echo "✅ SSH connection successful!"
        break
    else
        echo "⏳ Not ready yet, waiting 30 seconds..."
        sleep 30
    fi
done

if [ "$SSH_READY" = false ]; then
    echo "❌ SSH connection failed after 6 minutes"
    echo "   The instance may still be initializing or there may be a network issue"
    exit 1
fi

echo "✅ SSH connection established"

# Check and install Docker if needed with retries
echo "🐳 Checking Docker installation..."
DOCKER_READY=false
for i in {1..6}; do  # Try for up to 3 minutes
    DOCKER_CHECK=$(ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=15 ec2-user@${TARGET_IP} "
        # Check if Docker is installed and running
        if command -v docker >/dev/null 2>&1; then
            if sudo docker info >/dev/null 2>&1; then
                echo 'RUNNING'
            else
                echo 'INSTALLED_NOT_RUNNING'
            fi
        else
            echo 'NOT_INSTALLED'
        fi
    " 2>/dev/null || echo "CONNECTION_FAILED")
    
    if [ "$DOCKER_CHECK" = "RUNNING" ]; then
        DOCKER_READY=true
        echo "✅ Docker is already installed and running"
        break
    elif [ "$DOCKER_CHECK" = "INSTALLED_NOT_RUNNING" ]; then
        echo "🔄 Docker is installed but not running, starting it..."
        ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=15 ec2-user@${TARGET_IP} "
            sudo systemctl start docker
            sudo systemctl enable docker
            echo 'Docker service started'
        "
        DOCKER_READY=true
        break
    elif [ "$DOCKER_CHECK" = "CONNECTION_FAILED" ]; then
        echo "   Attempt $i/6: SSH connection issues, waiting 30 seconds..."
        sleep 30
    else
        echo "   Attempt $i/6: Docker not installed yet, waiting 30 seconds..."
        sleep 30
    fi
done

if [ "$DOCKER_READY" = false ]; then
    echo "⚠️  Docker not ready after waiting, attempting fresh installation..."
    ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=30 ec2-user@${TARGET_IP} "
        set -e
        echo 'Installing Docker...'
        
        # Stop any existing Docker service
        sudo systemctl stop docker 2>/dev/null || true
        
        # Install Docker
        sudo yum update -y
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -a -G docker ec2-user
        
        # Verify installation
        if sudo docker info >/dev/null 2>&1; then
            echo 'Docker installation completed and verified'
        else
            echo 'Docker installation may have issues'
            exit 1
        fi
    "
    
    # Wait a moment for Docker to start
    echo "⏳ Waiting for Docker daemon to start..."
    sleep 10
else
    echo "✅ Docker is installed and ready"
fi

# Create deployment package
echo "📦 Creating deployment package..."
TEMP_DIR=$(mktemp -d)
DEPLOY_DIR="${TEMP_DIR}/app"
mkdir -p "${DEPLOY_DIR}"

# Copy application files
echo "📁 Copying application files..."

# Copy core files (these should exist based on pre-flight check)
cp "${PROJECT_ROOT}/app.py" "${DEPLOY_DIR}/"
cp "${PROJECT_ROOT}/requirements.txt" "${DEPLOY_DIR}/"
cp "${PROJECT_ROOT}/Dockerfile" "${DEPLOY_DIR}/"
cp "${PROJECT_ROOT}/.env" "${DEPLOY_DIR}/"

# Verify .env file was copied
if [ ! -f "${DEPLOY_DIR}/.env" ]; then
    echo "❌ Error: .env file failed to copy to deployment package"
    echo "   Source file exists: $(ls -la "${PROJECT_ROOT}/.env" 2>/dev/null || echo 'NO')"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Copy optional files and directories
cp "${PROJECT_ROOT}/prompts.json" "${DEPLOY_DIR}/" 2>/dev/null || echo "⚠️  prompts.json not found (optional)"
cp -r "${PROJECT_ROOT}/static" "${DEPLOY_DIR}/" 2>/dev/null || echo "⚠️  static directory not found (optional)"
cp -r "${PROJECT_ROOT}/templates" "${DEPLOY_DIR}/" 2>/dev/null || echo "⚠️  templates directory not found (optional)"
cp -r "${PROJECT_ROOT}/docs" "${DEPLOY_DIR}/" 2>/dev/null || echo "⚠️  docs directory not found (optional)"

echo "✅ Core application files copied"

echo "📁 Files to transfer:"
ls -la "${DEPLOY_DIR}"

# Verify essential files are present
echo "🔍 Verifying essential files..."
if [ ! -f "${DEPLOY_DIR}/Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found in deployment package"
    echo "   Make sure Dockerfile exists in the glossary directory"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

if [ ! -f "${DEPLOY_DIR}/app.py" ]; then
    echo "❌ Error: app.py not found in deployment package"
    echo "   Make sure app.py exists in the glossary directory"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

if [ ! -f "${DEPLOY_DIR}/requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found in deployment package"
    echo "   Make sure requirements.txt exists in the glossary directory"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo "✅ Essential files verified"

# Transfer files to EC2
echo "🚀 Transferring files to EC2..."

# Clean up any existing files first
ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no ec2-user@${TARGET_IP} "
    sudo rm -rf /home/ec2-user/app/*
    echo '🧹 Cleaned existing app directory'
"

# Transfer all files including hidden files (.env) and directories
# First transfer normal files and directories
scp -i "${KEY_PATH}" -r -o StrictHostKeyChecking=no "${DEPLOY_DIR}"/*.py "${DEPLOY_DIR}"/*.txt "${DEPLOY_DIR}"/*.json "${DEPLOY_DIR}"/Dockerfile "${DEPLOY_DIR}"/docs/ ec2-user@${TARGET_IP}:/home/ec2-user/app/ 2>/dev/null || true
# Then transfer hidden files like .env
scp -i "${KEY_PATH}" -o StrictHostKeyChecking=no "${DEPLOY_DIR}"/.[^.]* ec2-user@${TARGET_IP}:/home/ec2-user/app/ 2>/dev/null || true

# Clean up temp directory
rm -rf "${TEMP_DIR}"

# Verify files transferred correctly
echo "🔍 Verifying file transfer..."
ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no ec2-user@${TARGET_IP} "
    echo 'Files in /home/ec2-user/app:'
    ls -la /home/ec2-user/app/
    echo ''
    
    # Verify essential files
    if [ ! -f '/home/ec2-user/app/Dockerfile' ]; then
        echo '❌ Dockerfile missing after transfer'
        exit 1
    fi
    
    if [ ! -f '/home/ec2-user/app/app.py' ]; then
        echo '❌ app.py missing after transfer'
        exit 1
    fi
    
    if [ ! -f '/home/ec2-user/app/.env' ]; then
        echo '❌ .env file missing after transfer'
        exit 1
    fi
    
    echo '✅ All essential files transferred successfully'
"
# Build Docker image with progress monitoring
echo "🔨 Building Docker image on EC2..."
echo "⏳ This may take 3-5 minutes for first build..."

ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no ec2-user@${TARGET_IP} "
    set -e
    cd /home/ec2-user/app
    
    # Determine image tag based on environment
    if [ '${ENVIRONMENT}' = 'test' ]; then
        IMAGE_TAG='glossary-local:test'
    else
        IMAGE_TAG='glossary-local:latest'
    fi
    
    echo '🔨 Building Docker image: '\$IMAGE_TAG
    echo '📦 This will install Python dependencies and may take several minutes...'
    
    # Build with timeout (10 minutes max)
    timeout 600 sudo docker build --platform linux/amd64 -t \$IMAGE_TAG . || {
        echo '❌ Docker build timed out or failed'
        echo '🔍 Checking build logs...'
        sudo docker system prune -f
        exit 1
    }
    
    echo '✅ Image built successfully!'
    echo '📋 Available images:'
    sudo docker images | grep glossary-local || echo 'No glossary-local images found'
    
    echo '🧪 Testing image...'
    sudo docker run --rm \$IMAGE_TAG python --version
    
    echo '✅ Image test passed!'
"

echo ""
echo "🎉 Files transferred and image built successfully!"
echo ""
echo "📝 NEXT STEPS:"
echo "   1. Run: ./04-deploy-app.sh ${ENVIRONMENT} (to deploy the app)"
echo "   2. Or SSH and deploy manually: ssh -i \"${KEY_PATH}\" ec2-user@${TARGET_IP}"
echo "      Then run: ./deploy.sh ${ENVIRONMENT}"
echo ""
echo "🔗 ACCESS:"
if [ "${ENVIRONMENT}" = "test" ]; then
    echo "   Test App: http://${TARGET_IP}:8080 (after deployment)"
    echo "   Test Health: http://${TARGET_IP}:8080/health"
else
    echo "   Prod App: http://${TARGET_IP} (after deployment)"
    echo "   Prod Health: http://${TARGET_IP}/health"
fi
echo ""
