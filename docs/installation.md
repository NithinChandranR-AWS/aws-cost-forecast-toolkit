# 📘 Installation Guide

This guide provides detailed installation instructions for the AWS Cost Forecast Toolkit across different environments.

## 🚀 Quick Start (Recommended)

### AWS CloudShell (Zero Installation)
The easiest way to get started is using AWS CloudShell, which has all dependencies pre-installed.

1. **Open AWS CloudShell**
   - Log into your AWS Console
   - Click the CloudShell icon (terminal) in the top navigation bar
   - Wait for CloudShell to initialize (30-60 seconds)

2. **Clone and Setup**
   ```bash
   # Clone the repository
   git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
   cd aws-cost-forecast-toolkit
   
   # Run setup script
   ./scripts/setup.sh
   
   # Start forecasting
   ./scripts/forecast-data-fetch.sh
   ```

That's it! You're ready to generate cost forecasts.

## 💻 Local Installation

### Prerequisites
Before installing locally, ensure you have:

- **Operating System**: Linux, macOS, or Windows with WSL
- **Bash**: Version 4.0 or higher
- **AWS CLI**: Version 2.0 or higher
- **jq**: JSON processor
- **curl**: HTTP client (usually pre-installed)

### Step-by-Step Installation

#### 1. Install AWS CLI
```bash
# Linux/WSL
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Or using Homebrew
brew install awscli
```

#### 2. Install jq
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y jq

# Amazon Linux/RHEL/CentOS
sudo yum install -y jq

# macOS
brew install jq

# Windows (using Chocolatey)
choco install jq
```

#### 3. Configure AWS Credentials
```bash
# Interactive configuration
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### 4. Clone and Setup Repository
```bash
# Clone the repository
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Run setup and validation
./scripts/setup.sh

# Test installation
./tests/run-tests.sh
```

## 🐳 Docker Installation (Advanced)

For containerized environments, you can create a Docker setup:

### Dockerfile
```dockerfile
FROM amazonlinux:2

# Install dependencies
RUN yum update -y && \
    yum install -y aws-cli jq git bash curl && \
    yum clean all

# Create working directory
WORKDIR /app

# Copy toolkit
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh tests/*.sh

# Set entrypoint
ENTRYPOINT ["./scripts/forecast-data-fetch.sh"]
```

### Build and Run
```bash
# Build Docker image
docker build -t aws-cost-forecast-toolkit .

# Run with AWS credentials
docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  aws-cost-forecast-toolkit
```

## ☁️ AWS EC2 Installation

### Amazon Linux 2
```bash
# Update system
sudo yum update -y

# Install dependencies (AWS CLI pre-installed)
sudo yum install -y jq git

# Clone repository
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Setup
./scripts/setup.sh
```

### Ubuntu/Debian
```bash
# Update system
sudo apt-get update

# Install dependencies
sudo apt-get install -y awscli jq git curl

# Clone repository
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Setup
./scripts/setup.sh
```

## 🔧 Environment Configuration

### Required AWS Permissions
Your AWS user/role needs these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ce:GetCostAndUsage",
                "ce:GetCostForecast",
                "ce:GetDimensionValues",
                "ce:GetReservationCoverage",
                "ce:GetReservationPurchaseRecommendation",
                "ce:GetReservationUtilization"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-forecast-bucket",
                "arn:aws:s3:::your-forecast-bucket/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "quicksight:CreateDataSet",
                "quicksight:CreateAnalysis",
                "quicksight:CreateDashboard",
                "quicksight:DescribeAccountSettings"
            ],
            "Resource": "*"
        }
    ]
}
```

### Environment Variables
Set these optional environment variables for default behavior:

```bash
# Default S3 bucket for storing forecast data
export FORECAST_DEFAULT_BUCKET="my-cost-forecasts"

# Default AWS region
export FORECAST_DEFAULT_REGION="us-east-1"

# Email for notifications
export FORECAST_EMAIL_REPORTS="admin@company.com"

# Enable debug logging
export FORECAST_DEBUG="true"

# Maximum parallel processes
export FORECAST_MAX_PARALLEL="10"
```

## 🧪 Verification

### Run Tests
```bash
# Basic functionality test
./tests/run-tests.sh

# Verbose testing
./tests/run-tests.sh --verbose
```

### Test AWS Access
```bash
# Check AWS credentials
aws sts get-caller-identity

# Test Cost Explorer access
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-02 \
  --granularity DAILY \
  --metrics BlendedCost

# Test S3 access (if using S3)
aws s3 ls s3://your-bucket-name
```

### Manual Test Run
```bash
# Run with dry-run mode
./scripts/forecast-data-fetch.sh --dry-run

# Run setup check only
./scripts/setup.sh --check-only
```

## 🚨 Troubleshooting

### Common Issues

#### "AWS CLI not found"
```bash
# Check if AWS CLI is installed
which aws

# Check version
aws --version

# If not installed, follow AWS CLI installation steps above
```

#### "jq: command not found"
```bash
# Install jq based on your OS (see installation steps above)
# For CloudShell, this shouldn't happen
```

#### "Permission denied" errors
```bash
# Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# Check file permissions
ls -la scripts/
```

#### "AWS credentials not configured"
```bash
# Configure AWS CLI
aws configure

# Or check existing configuration
aws configure list

# Test credentials
aws sts get-caller-identity
```

#### "Cost Explorer access denied"
- Ensure your IAM user/role has Cost Explorer permissions
- Cost Explorer must be enabled in your AWS account
- Some organizations restrict Cost Explorer access

### Getting Help

1. **Check Prerequisites**: Run `./scripts/setup.sh --check-only`
2. **Run Tests**: Execute `./tests/run-tests.sh` for validation
3. **Enable Debug**: Set `export FORECAST_DEBUG=true` for verbose output
4. **Check Logs**: Review log files in the `output/` directory
5. **GitHub Issues**: Report issues at [GitHub Issues](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues)

## 📋 Next Steps

After successful installation:

1. **Configure Settings**: Review `config/user.conf.sample`
2. **Run First Forecast**: Execute `./scripts/forecast-data-fetch.sh`
3. **Create Dashboard**: Run `./scripts/quicksight-dashboard.sh`
4. **Schedule Automation**: Set up cron jobs for regular forecasts
5. **Explore Examples**: Check the `examples/` directory

## 🔄 Updates

### Updating the Toolkit
```bash
# Pull latest changes
git pull origin main

# Re-run setup
./scripts/setup.sh

# Test updated version
./tests/run-tests.sh
```

### Version Information
```bash
# Check script versions
./scripts/forecast-data-fetch.sh --version
./scripts/quicksight-dashboard.sh --version
./scripts/setup.sh --version
```

---

**Need help?** Check our [Troubleshooting Guide](troubleshooting.md) or [create an issue](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues).
