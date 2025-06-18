# 🔧 Configuration Options

This guide covers all configuration options available in the AWS Cost Forecast Toolkit, from basic settings to advanced customization.

## 📋 Configuration Methods

The toolkit supports multiple configuration methods, listed in order of precedence:

1. **Command Line Arguments** (highest priority)
2. **Environment Variables**
3. **Configuration Files**
4. **Interactive Prompts** (lowest priority)

## 🚀 Quick Configuration

### Basic Environment Variables
```bash
# Essential settings
export FORECAST_DEFAULT_BUCKET="my-cost-forecasts"
export FORECAST_DEFAULT_REGION="us-east-1"
export FORECAST_EMAIL_REPORTS="admin@company.com"

# Run with defaults
./scripts/forecast-data-fetch.sh
```

### Configuration File
```bash
# Create user configuration
cp config/user.conf.sample config/user.conf

# Edit configuration
nano config/user.conf

# Use configuration
export FORECAST_CONFIG="config/user.conf"
./scripts/forecast-data-fetch.sh
```

## 📝 Configuration File Format

### Sample Configuration File
```bash
# config/user.conf
# AWS Cost Forecast Toolkit - User Configuration

# =============================================================================
# BASIC SETTINGS
# =============================================================================

# Default S3 bucket for storing forecast data
DEFAULT_BUCKET="enterprise-cost-forecasts"

# Default AWS region
DEFAULT_REGION="us-east-1"

# Email for notifications and reports
EMAIL_NOTIFICATIONS="finance@company.com"

# =============================================================================
# FORECAST SETTINGS
# =============================================================================

# Default forecast period in days (30, 90, 180, 365)
DEFAULT_FORECAST_DAYS="90"

# Default granularity (DAILY, MONTHLY)
DEFAULT_GRANULARITY="MONTHLY"

# Default metrics (comma-separated)
# Options: AMORTIZED_COST, BLENDED_COST, NET_AMORTIZED_COST, NET_UNBLENDED_COST, UNBLENDED_COST, USAGE_QUANTITY, NORMALIZED_USAGE_AMOUNT
DEFAULT_METRICS="AMORTIZED_COST,BLENDED_COST"

# Default dimensions (comma-separated)
# Options: SERVICE, REGION, LINKED_ACCOUNT, INSTANCE_TYPE, etc.
DEFAULT_DIMENSIONS="SERVICE,REGION,LINKED_ACCOUNT"

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

# Maximum parallel processes for API calls
MAX_PARALLEL_JOBS="10"

# API rate limiting delay (seconds)
API_DELAY="0.5"

# Enable caching of dimension values (true/false)
ENABLE_CACHING="true"

# Cache expiration time (minutes)
CACHE_EXPIRATION="60"

# =============================================================================
# QUICKSIGHT SETTINGS
# =============================================================================

# Auto-create QuickSight dashboards (true/false)
QUICKSIGHT_AUTO_CREATE="false"

# QuickSight dashboard theme
QUICKSIGHT_THEME="CLASSIC"

# Enable QuickSight email reports (true/false)
QUICKSIGHT_EMAIL_REPORTS="true"

# =============================================================================
# LOGGING AND DEBUG
# =============================================================================

# Enable debug logging (true/false)
DEBUG_LOGGING="false"

# Log level (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL="INFO"

# Keep temporary files for debugging (true/false)
KEEP_TEMP_FILES="false"

# =============================================================================
# ADVANCED SETTINGS
# =============================================================================

# Custom output directory
OUTPUT_DIRECTORY=""

# Custom temporary directory
TEMP_DIRECTORY=""

# Enable compression for output files (true/false)
COMPRESS_OUTPUT="false"

# Retry attempts for failed API calls
MAX_RETRIES="3"

# Timeout for API calls (seconds)
API_TIMEOUT="30"
```

## 🌍 Environment Variables Reference

### Core Settings
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `FORECAST_DEFAULT_BUCKET` | S3 bucket for data storage | None | `my-forecasts` |
| `FORECAST_DEFAULT_REGION` | AWS region | `us-east-1` | `us-west-2` |
| `FORECAST_EMAIL_REPORTS` | Email for notifications | None | `admin@company.com` |
| `FORECAST_CONFIG` | Path to configuration file | None | `config/prod.conf` |

### Forecast Parameters
| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `FORECAST_DEFAULT_DAYS` | Forecast period in days | `90` | `30`, `90`, `180`, `365` |
| `FORECAST_GRANULARITY` | Data granularity | `MONTHLY` | `DAILY`, `MONTHLY` |
| `FORECAST_METRICS` | Comma-separated metrics | None | `AMORTIZED_COST,BLENDED_COST` |
| `FORECAST_DIMENSIONS` | Comma-separated dimensions | None | `SERVICE,REGION` |

### Performance Settings
| Variable | Description | Default | Range |
|----------|-------------|---------|-------|
| `FORECAST_MAX_PARALLEL` | Max parallel processes | `10` | `1-50` |
| `FORECAST_API_DELAY` | API call delay (seconds) | `0.5` | `0.1-5.0` |
| `FORECAST_MAX_RETRIES` | Max retry attempts | `3` | `1-10` |
| `FORECAST_API_TIMEOUT` | API timeout (seconds) | `30` | `10-300` |

### Debug and Logging
| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `FORECAST_DEBUG` | Enable debug mode | `false` | `true`, `false` |
| `FORECAST_LOG_LEVEL` | Logging level | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `FORECAST_KEEP_TEMP` | Keep temporary files | `false` | `true`, `false` |
| `FORECAST_VERBOSE` | Verbose output | `false` | `true`, `false` |

## 🎯 Command Line Arguments

### Main Forecast Script
```bash
./scripts/forecast-data-fetch.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  --start-date DATE       Set custom start date (YYYY-MM-DD)
  --end-date DATE         Set custom end date (YYYY-MM-DD)
  --bucket BUCKET         Set S3 bucket for output
  --region REGION         Set AWS region
  --granularity GRAN      Set granularity (DAILY/MONTHLY)
  --metrics METRICS       Comma-separated metrics list
  --dimensions DIMS       Comma-separated dimensions list
  --parallel NUM          Max parallel processes
  --dry-run               Validate configuration without running
  --quiet                 Suppress non-essential output
  --debug                 Enable debug mode
  --config FILE           Use specific configuration file
```

### QuickSight Dashboard Script
```bash
./scripts/quicksight-dashboard.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  --bucket BUCKET         S3 bucket containing forecast data
  --region REGION         AWS region for QuickSight
  --manual                Skip automated setup, show manual instructions
  --auto-create           Attempt automated dashboard creation
  --theme THEME           QuickSight theme (CLASSIC, MIDNIGHT, etc.)
```

### Setup Script
```bash
./scripts/setup.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  --check-only            Only check prerequisites, don't setup
  --skip-aws              Skip AWS access checks
  --install-deps          Install missing dependencies (where possible)
```

## 📊 Metrics Configuration

### Available Metrics
```bash
# Cost Metrics
AMORTIZED_COST          # Amortized cost including RIs/SPs
BLENDED_COST           # Blended cost across accounts
NET_AMORTIZED_COST     # Net amortized cost after credits
NET_UNBLENDED_COST     # Net unblended cost after credits
UNBLENDED_COST         # Actual cost without blending

# Usage Metrics
USAGE_QUANTITY         # Usage quantity metrics
NORMALIZED_USAGE_AMOUNT # Normalized usage amount
```

### Metric Selection Examples
```bash
# Cost-focused analysis
export FORECAST_METRICS="AMORTIZED_COST,BLENDED_COST"

# Comprehensive cost analysis
export FORECAST_METRICS="AMORTIZED_COST,BLENDED_COST,UNBLENDED_COST"

# Usage analysis
export FORECAST_METRICS="USAGE_QUANTITY,NORMALIZED_USAGE_AMOUNT"

# All metrics
export FORECAST_METRICS="AMORTIZED_COST,BLENDED_COST,NET_AMORTIZED_COST,NET_UNBLENDED_COST,UNBLENDED_COST,USAGE_QUANTITY,NORMALIZED_USAGE_AMOUNT"
```

## 🎯 Dimensions Configuration

### Available Dimensions
```bash
# Account and Organization
LINKED_ACCOUNT          # AWS account ID
LINKED_ACCOUNT_NAME     # AWS account name
BILLING_ENTITY          # Billing entity
LEGAL_ENTITY_NAME       # Legal entity name

# Service and Resource
SERVICE                 # AWS service name
OPERATION              # AWS operation
USAGE_TYPE             # Usage type
USAGE_TYPE_GROUP       # Usage type group
RECORD_TYPE            # Record type

# Infrastructure
REGION                 # AWS region
AZ                     # Availability zone
INSTANCE_TYPE          # EC2 instance type
INSTANCE_TYPE_FAMILY   # Instance type family
PLATFORM               # Platform (Linux/Windows)
TENANCY                # Tenancy (Shared/Dedicated/Host)
OPERATING_SYSTEM       # Operating system

# Purchasing
PURCHASE_TYPE          # On-Demand/Reserved/Spot
RESERVATION_ID         # Reservation ID
SAVINGS_PLAN_ARN       # Savings Plan ARN
SCOPE                  # Scope (AZ/Region)
SUBSCRIPTION_ID        # Subscription ID

# Database
DATABASE_ENGINE        # Database engine
DEPLOYMENT_OPTION      # Deployment option
```

### Dimension Selection Examples
```bash
# Service analysis
export FORECAST_DIMENSIONS="SERVICE,REGION"

# Account analysis
export FORECAST_DIMENSIONS="LINKED_ACCOUNT,LINKED_ACCOUNT_NAME,SERVICE"

# Infrastructure analysis
export FORECAST_DIMENSIONS="REGION,AZ,INSTANCE_TYPE"

# Comprehensive analysis
export FORECAST_DIMENSIONS="SERVICE,REGION,LINKED_ACCOUNT,INSTANCE_TYPE,PURCHASE_TYPE"

# Recommended dimensions (balanced)
export FORECAST_DIMENSIONS="SERVICE,REGION,LINKED_ACCOUNT"
```

## ⚡ Performance Tuning

### Parallel Processing
```bash
# Conservative (for small accounts or limited resources)
export FORECAST_MAX_PARALLEL="5"

# Balanced (default)
export FORECAST_MAX_PARALLEL="10"

# Aggressive (for large accounts with good network)
export FORECAST_MAX_PARALLEL="20"

# Maximum (use with caution)
export FORECAST_MAX_PARALLEL="50"
```

### API Rate Limiting
```bash
# Conservative (avoid rate limiting)
export FORECAST_API_DELAY="1.0"

# Balanced (default)
export FORECAST_API_DELAY="0.5"

# Aggressive (faster but may hit limits)
export FORECAST_API_DELAY="0.1"
```

### Caching Configuration
```bash
# Enable caching for faster repeated runs
export FORECAST_ENABLE_CACHING="true"
export FORECAST_CACHE_EXPIRATION="60"  # minutes

# Disable caching for always fresh data
export FORECAST_ENABLE_CACHING="false"
```

## 🗂️ Output Configuration

### Output Directory Structure
```bash
# Default structure
output/
├── YYYYMMDD_HHMMSS/          # Timestamped directories
│   ├── forecast_*.csv        # Main forecast data
│   ├── forecast_*.log        # Execution logs
│   ├── quicksight-manifest.json  # QuickSight manifest
│   └── temp/                 # Temporary files
```

### Custom Output Configuration
```bash
# Custom output directory
export FORECAST_OUTPUT_DIR="/custom/path/forecasts"

# Custom temporary directory
export FORECAST_TEMP_DIR="/tmp/forecast-temp"

# Enable output compression
export FORECAST_COMPRESS_OUTPUT="true"

# Custom file naming
export FORECAST_FILE_PREFIX="company-forecast"
```

## 🔐 Security Configuration

### AWS Credentials
```bash
# Method 1: AWS CLI configuration
aws configure

# Method 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Method 3: IAM roles (recommended for EC2/Lambda)
# No configuration needed - uses instance profile

# Method 4: AWS profiles
export AWS_PROFILE="production"
```

### S3 Security
```bash
# S3 bucket with encryption
export FORECAST_S3_ENCRYPTION="AES256"

# S3 bucket with KMS encryption
export FORECAST_S3_KMS_KEY="arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# S3 bucket access logging
export FORECAST_S3_ACCESS_LOGGING="true"
```

## 🎨 QuickSight Configuration

### Dashboard Settings
```bash
# Auto-create dashboards
export FORECAST_QUICKSIGHT_AUTO="true"

# Dashboard theme
export FORECAST_QUICKSIGHT_THEME="MIDNIGHT"

# Email reports
export FORECAST_QUICKSIGHT_EMAIL="true"
export FORECAST_QUICKSIGHT_EMAIL_SCHEDULE="DAILY"

# Dashboard permissions
export FORECAST_QUICKSIGHT_SHARE_GROUP="arn:aws:quicksight:us-east-1:123456789012:group/default/finance-team"
```

### Data Source Configuration
```bash
# Custom data source name
export FORECAST_QUICKSIGHT_DATASOURCE="CostForecastData"

# Custom dataset name
export FORECAST_QUICKSIGHT_DATASET="CostForecastDataset"

# Refresh schedule
export FORECAST_QUICKSIGHT_REFRESH="DAILY"
export FORECAST_QUICKSIGHT_REFRESH_TIME="06:00"
```

## 🔧 Advanced Configuration

### Multi-Environment Setup
```bash
# config/development.conf
DEFAULT_BUCKET="dev-cost-forecasts"
DEFAULT_REGION="us-west-2"
DEBUG_LOGGING="true"
MAX_PARALLEL_JOBS="5"

# config/staging.conf
DEFAULT_BUCKET="staging-cost-forecasts"
DEFAULT_REGION="us-east-1"
DEBUG_LOGGING="false"
MAX_PARALLEL_JOBS="10"

# config/production.conf
DEFAULT_BUCKET="prod-cost-forecasts"
DEFAULT_REGION="us-east-1"
DEBUG_LOGGING="false"
MAX_PARALLEL_JOBS="20"
QUICKSIGHT_AUTO_CREATE="true"
EMAIL_NOTIFICATIONS="finance@company.com"
```

### Custom Filters
```bash
# Service-specific forecasting
export FORECAST_SERVICE_FILTER="Amazon EC2,Amazon S3,Amazon RDS"

# Account-specific forecasting
export FORECAST_ACCOUNT_FILTER="123456789012,234567890123"

# Region-specific forecasting
export FORECAST_REGION_FILTER="us-east-1,us-west-2"

# Date range filters
export FORECAST_EXCLUDE_WEEKENDS="true"
export FORECAST_BUSINESS_HOURS_ONLY="false"
```

### Integration Settings
```bash
# Slack integration
export FORECAST_SLACK_WEBHOOK="https://hooks.slack.com/services/..."
export FORECAST_SLACK_CHANNEL="#finance"

# Email integration
export FORECAST_SMTP_SERVER="smtp.company.com"
export FORECAST_SMTP_PORT="587"
export FORECAST_SMTP_USER="forecast@company.com"

# Webhook notifications
export FORECAST_WEBHOOK_URL="https://api.company.com/webhooks/forecast"
export FORECAST_WEBHOOK_SECRET="your-webhook-secret"
```

## 🧪 Testing Configuration

### Test Environment
```bash
# Test configuration
export FORECAST_TEST_MODE="true"
export FORECAST_TEST_BUCKET="test-cost-forecasts"
export FORECAST_TEST_REGION="us-east-1"
export FORECAST_DRY_RUN="true"

# Mock data for testing
export FORECAST_USE_MOCK_DATA="true"
export FORECAST_MOCK_DATA_FILE="tests/mock-data.json"
```

### Validation Settings
```bash
# Strict validation
export FORECAST_STRICT_VALIDATION="true"

# Skip validation for faster testing
export FORECAST_SKIP_VALIDATION="false"

# Validate configuration only
export FORECAST_CONFIG_ONLY="true"
```

## 📋 Configuration Validation

### Validate Configuration
```bash
# Check current configuration
./scripts/setup.sh --check-only

# Validate specific configuration file
FORECAST_CONFIG="config/production.conf" ./scripts/setup.sh --check-only

# Test configuration with dry run
./scripts/forecast-data-fetch.sh --dry-run
```

### Configuration Troubleshooting
```bash
# Show current configuration
./scripts/forecast-data-fetch.sh --show-config

# Debug configuration loading
FORECAST_DEBUG="true" ./scripts/forecast-data-fetch.sh --dry-run

# Validate AWS permissions
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-02 --granularity DAILY --metrics BlendedCost
```

## 🔄 Configuration Migration

### Upgrading Configuration
```bash
# Backup existing configuration
cp config/user.conf config/user.conf.backup

# Update to new format
./scripts/migrate-config.sh config/user.conf

# Validate updated configuration
./scripts/setup.sh --check-only
```

### Environment Migration
```bash
# Export current environment
env | grep FORECAST_ > current-env.txt

# Import to new environment
source current-env.txt
```

---

**Next Steps**: Check out our [Troubleshooting Guide](troubleshooting.md) for help with configuration issues.
