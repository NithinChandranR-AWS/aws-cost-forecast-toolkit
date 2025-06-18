# 🐛 Troubleshooting Guide

This comprehensive troubleshooting guide helps you resolve common issues with the AWS Cost Forecast Toolkit.

## 🚨 Quick Diagnostics

### Run Diagnostic Check
```bash
# Comprehensive system check
./scripts/setup.sh --check-only

# Test all functionality
./tests/run-tests.sh

# Debug mode execution
FORECAST_DEBUG="true" ./scripts/forecast-data-fetch.sh --dry-run
```

### Check System Status
```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check dependencies
which jq && jq --version
which curl && curl --version

# Check permissions
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-02 --granularity DAILY --metrics BlendedCost
```

## 🔧 Installation Issues

### AWS CLI Not Found
**Error**: `aws: command not found`

**Solutions**:
```bash
# CloudShell: This shouldn't happen, contact AWS support
# Local installation:

# Linux/WSL
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli
# OR
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version
```

### jq Not Found
**Error**: `jq: command not found`

**Solutions**:
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y jq

# Amazon Linux/RHEL/CentOS
sudo yum install -y jq

# macOS
brew install jq

# Manual installation
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq
```

### Permission Denied Errors
**Error**: `Permission denied` when running scripts

**Solutions**:
```bash
# Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# Check current permissions
ls -la scripts/

# Fix all permissions
find . -name "*.sh" -exec chmod +x {} \;
```

## 🔐 AWS Authentication Issues

### Credentials Not Configured
**Error**: `Unable to locate credentials`

**Solutions**:
```bash
# Method 1: Interactive configuration
aws configure

# Method 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Method 3: Use specific profile
export AWS_PROFILE="your-profile-name"

# Verify credentials
aws sts get-caller-identity
```

### Invalid Credentials
**Error**: `The security token included in the request is invalid`

**Solutions**:
```bash
# Check credential expiration
aws sts get-caller-identity

# Refresh credentials (if using temporary credentials)
aws sts get-session-token

# Reconfigure credentials
aws configure

# Check for multiple credential sources
env | grep AWS_
cat ~/.aws/credentials
cat ~/.aws/config
```

### Region Issues
**Error**: `You must specify a region`

**Solutions**:
```bash
# Set default region
aws configure set region us-east-1

# Use environment variable
export AWS_DEFAULT_REGION="us-east-1"

# Specify region in command
./scripts/forecast-data-fetch.sh --region us-east-1

# Check current region
aws configure get region
```

## 💰 Cost Explorer Issues

### Cost Explorer Access Denied
**Error**: `User is not authorized to perform: ce:GetCostAndUsage`

**Required Permissions**:
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
        }
    ]
}
```

**Solutions**:
```bash
# Test Cost Explorer access
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-02 \
  --granularity DAILY \
  --metrics BlendedCost

# Check IAM permissions
aws iam get-user-policy --user-name your-username --policy-name CostExplorerPolicy
aws iam list-attached-user-policies --user-name your-username
```

### Cost Explorer Not Enabled
**Error**: `Cost Explorer is not enabled for this account`

**Solutions**:
1. **Enable Cost Explorer**:
   - Go to AWS Console → Billing & Cost Management
   - Click "Cost Explorer" in the left navigation
   - Click "Enable Cost Explorer"
   - Wait 24 hours for data to populate

2. **Organization Account Issues**:
   - Must be enabled by the master/management account
   - Contact your AWS administrator

### No Cost Data Available
**Error**: `No cost data found for the specified time period`

**Possible Causes & Solutions**:
```bash
# 1. New AWS account (< 24 hours old)
# Solution: Wait 24-48 hours for cost data to appear

# 2. No AWS usage in specified period
# Solution: Check a different time period
./scripts/forecast-data-fetch.sh --start-date 2024-01-01 --end-date 2024-01-31

# 3. Incorrect date format
# Solution: Use YYYY-MM-DD format
./scripts/forecast-data-fetch.sh --start-date 2024-01-01 --end-date 2024-01-02

# 4. Future dates
# Solution: Use past dates for cost data, future dates for forecasts
```

## 📊 Data Collection Issues

### API Rate Limiting
**Error**: `Throttling: Rate exceeded` or `TooManyRequestsException`

**Solutions**:
```bash
# Increase API delay
export FORECAST_API_DELAY="1.0"  # 1 second delay

# Reduce parallel processing
export FORECAST_MAX_PARALLEL="5"

# Use exponential backoff
export FORECAST_MAX_RETRIES="5"

# Run during off-peak hours
# Schedule for early morning or late evening
```

### Large Dataset Issues
**Error**: Script hangs or runs very slowly

**Solutions**:
```bash
# Reduce scope - select fewer dimensions
./scripts/forecast-data-fetch.sh
# Select: 99) Recommended dimensions instead of 0) All dimensions

# Use monthly granularity for long periods
# Select: 2) MONTHLY instead of 1) DAILY

# Limit time period
# Use 90 days instead of 365 days for initial testing

# Increase timeout
export FORECAST_API_TIMEOUT="60"  # 60 seconds
```

### Memory Issues
**Error**: `Cannot allocate memory` or script crashes

**Solutions**:
```bash
# Reduce parallel processing
export FORECAST_MAX_PARALLEL="3"

# Process smaller chunks
# Run multiple smaller forecasts instead of one large one

# Clear temporary files
rm -rf output/*/temp/

# Check available memory
free -h
df -h
```

## 🗄️ S3 Issues

### S3 Access Denied
**Error**: `Access Denied` when uploading to S3

**Solutions**:
```bash
# Check bucket exists and you have access
aws s3 ls s3://your-bucket-name

# Test S3 permissions
aws s3 cp /tmp/test.txt s3://your-bucket-name/test.txt
aws s3 rm s3://your-bucket-name/test.txt

# Required S3 permissions:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
```

### S3 Bucket Not Found
**Error**: `NoSuchBucket: The specified bucket does not exist`

**Solutions**:
```bash
# Create the bucket
aws s3 mb s3://your-bucket-name --region us-east-1

# Check bucket region
aws s3api get-bucket-location --bucket your-bucket-name

# Use correct region
./scripts/forecast-data-fetch.sh --bucket your-bucket-name --region us-east-1
```

### S3 Upload Failures
**Error**: Upload fails silently or with timeout

**Solutions**:
```bash
# Check network connectivity
curl -I https://s3.amazonaws.com

# Increase timeout
export AWS_CLI_FILE_TIMEOUT=0
export AWS_CLI_S3_TIMEOUT=0

# Use multipart upload for large files
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.max_concurrent_requests 10
```

## 📈 QuickSight Issues

### QuickSight Not Available
**Error**: `QuickSight is not available in this region`

**Solutions**:
```bash
# Check QuickSight availability
aws quicksight describe-account-settings --aws-account-id $(aws sts get-caller-identity --query Account --output text)

# Use supported region
./scripts/quicksight-dashboard.sh --region us-east-1

# QuickSight supported regions:
# us-east-1, us-west-2, eu-west-1, ap-southeast-1, ap-southeast-2, ap-northeast-1
```

### QuickSight Access Denied
**Error**: `User is not authorized to perform: quicksight:DescribeAccountSettings`

**Required Permissions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "quicksight:CreateDataSet",
                "quicksight:CreateAnalysis",
                "quicksight:CreateDashboard",
                "quicksight:DescribeAccountSettings",
                "quicksight:DescribeDataSet",
                "quicksight:DescribeAnalysis",
                "quicksight:DescribeDashboard"
            ],
            "Resource": "*"
        }
    ]
}
```

### QuickSight Subscription Required
**Error**: `QuickSight subscription is required`

**Solutions**:
1. **Subscribe to QuickSight**:
   - Go to AWS Console → QuickSight
   - Choose subscription type (Standard or Enterprise)
   - Complete subscription process

2. **Use Manual Setup**:
   ```bash
   # Skip automated QuickSight setup
   ./scripts/quicksight-dashboard.sh --manual
   ```

## 🔄 Script Execution Issues

### Script Hangs or Freezes
**Symptoms**: Script stops responding, no output

**Debugging Steps**:
```bash
# Enable debug mode
FORECAST_DEBUG="true" ./scripts/forecast-data-fetch.sh

# Run with verbose output
./scripts/forecast-data-fetch.sh --verbose

# Check for background processes
ps aux | grep forecast

# Kill hung processes
pkill -f forecast-data-fetch

# Check system resources
top
htop  # if available
```

### Unexpected Script Termination
**Error**: Script exits without clear error message

**Solutions**:
```bash
# Check exit codes
echo $?  # Run immediately after script failure

# Enable error tracing
set -x
./scripts/forecast-data-fetch.sh

# Check system logs
tail -f /var/log/syslog  # Linux
tail -f /var/log/system.log  # macOS

# Run with error handling
bash -x ./scripts/forecast-data-fetch.sh
```

### Invalid Date Formats
**Error**: `Invalid date format` or date parsing errors

**Solutions**:
```bash
# Use correct format: YYYY-MM-DD
./scripts/forecast-data-fetch.sh --start-date 2024-01-01 --end-date 2024-01-31

# Check date command compatibility
date --version  # GNU date
date -j -f "%Y-%m-%d" "2024-01-01" "+%Y-%m-%d"  # BSD date (macOS)

# Use ISO format consistently
export LC_TIME=C
```

## 📁 File and Directory Issues

### Output Directory Permissions
**Error**: `Permission denied` when creating output files

**Solutions**:
```bash
# Check current directory permissions
ls -la

# Create output directory with correct permissions
mkdir -p output
chmod 755 output

# Use custom output directory
export FORECAST_OUTPUT_DIR="/tmp/forecasts"
mkdir -p "$FORECAST_OUTPUT_DIR"
```

### Disk Space Issues
**Error**: `No space left on device`

**Solutions**:
```bash
# Check disk space
df -h

# Clean up old forecasts
find output/ -name "*.csv" -mtime +30 -delete
find output/ -name "*.log" -mtime +7 -delete

# Use external storage
export FORECAST_OUTPUT_DIR="/external/storage/forecasts"

# Compress output files
export FORECAST_COMPRESS_OUTPUT="true"
```

### File Corruption
**Error**: Invalid CSV files or corrupted output

**Solutions**:
```bash
# Validate CSV files
head -5 output/latest/forecast_*.csv
tail -5 output/latest/forecast_*.csv

# Check file integrity
file output/latest/forecast_*.csv

# Re-run with clean environment
rm -rf output/*/temp/
./scripts/forecast-data-fetch.sh
```

## 🌐 Network Issues

### Connection Timeouts
**Error**: `Connection timed out` or `Network is unreachable`

**Solutions**:
```bash
# Test AWS connectivity
curl -I https://ce.us-east-1.amazonaws.com

# Increase timeouts
export FORECAST_API_TIMEOUT="60"
export AWS_CLI_READ_TIMEOUT=0
export AWS_CLI_CONNECT_TIMEOUT=60

# Check proxy settings
env | grep -i proxy
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

### DNS Resolution Issues
**Error**: `Could not resolve hostname`

**Solutions**:
```bash
# Test DNS resolution
nslookup ce.us-east-1.amazonaws.com
dig ce.us-east-1.amazonaws.com

# Use alternative DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Check network configuration
cat /etc/resolv.conf
ip route show
```

## 🔍 Data Quality Issues

### Missing or Incomplete Data
**Symptoms**: Fewer records than expected, missing services

**Troubleshooting**:
```bash
# Check dimension values
aws ce get-dimension-values \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --dimension SERVICE

# Verify time period
# Ensure you have cost data for the specified period

# Check filters
# Remove any service or account filters that might limit results

# Use broader dimensions
# Start with SERVICE, REGION, LINKED_ACCOUNT
```

### Inconsistent Forecasts
**Symptoms**: Forecast values seem unrealistic

**Validation Steps**:
```bash
# Compare with actual costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Check forecast confidence intervals
# Review LowerBound and UpperBound values in output

# Validate input parameters
# Ensure correct metrics and dimensions are selected
```

## 🧪 Testing and Validation

### Test Environment Setup
```bash
# Create test configuration
export FORECAST_TEST_MODE="true"
export FORECAST_DRY_RUN="true"
export FORECAST_DEBUG="true"

# Run validation tests
./tests/run-tests.sh --verbose

# Test with minimal data
./scripts/forecast-data-fetch.sh \
  --start-date $(date -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date -d '1 day ago' +%Y-%m-%d) \
  --dry-run
```

### Performance Testing
```bash
# Measure execution time
time ./scripts/forecast-data-fetch.sh --dry-run

# Monitor resource usage
# Terminal 1:
./scripts/forecast-data-fetch.sh

# Terminal 2:
watch -n 1 'ps aux | grep forecast; free -h'
```

## 📞 Getting Additional Help

### Collect Diagnostic Information
```bash
#!/bin/bash
# diagnostic-info.sh

echo "=== System Information ==="
uname -a
echo

echo "=== AWS CLI Version ==="
aws --version
echo

echo "=== AWS Configuration ==="
aws configure list
echo

echo "=== AWS Identity ==="
aws sts get-caller-identity
echo

echo "=== Dependencies ==="
which jq && jq --version
which curl && curl --version
echo

echo "=== Disk Space ==="
df -h
echo

echo "=== Memory ==="
free -h
echo

echo "=== Environment Variables ==="
env | grep -E "(AWS_|FORECAST_)" | sort
echo

echo "=== Recent Logs ==="
ls -la output/*/forecast_*.log 2>/dev/null | tail -5
```

### Support Channels
1. **GitHub Issues**: [Create an issue](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues)
2. **GitHub Discussions**: [Community support](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/discussions)
3. **Email Support**: rajashan@amazon.com

### When Reporting Issues
Include the following information:
- Operating system and version
- AWS CLI version
- Error messages (full text)
- Steps to reproduce
- Output from diagnostic script above
- Relevant log files

## 🔄 Recovery Procedures

### Clean Installation
```bash
# Remove existing installation
rm -rf aws-cost-forecast-toolkit

# Fresh clone
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Setup from scratch
./scripts/setup.sh
./tests/run-tests.sh
```

### Reset Configuration
```bash
# Backup current configuration
cp config/user.conf config/user.conf.backup

# Reset to defaults
cp config/user.conf.sample config/user.conf

# Clear environment variables
unset $(env | grep FORECAST_ | cut -d= -f1)

# Test with clean configuration
./scripts/forecast-data-fetch.sh
```

### Emergency Data Recovery
```bash
# Recover from S3 backup
aws s3 sync s3://your-backup-bucket/forecasts/ output/

# Restore from local backup
cp -r backup/output/* output/

# Regenerate corrupted files
./scripts/forecast-data-fetch.sh --start-date YYYY-MM-DD --end-date YYYY-MM-DD
```

---

**Still having issues?** Create a [GitHub issue](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues) with your diagnostic information.
