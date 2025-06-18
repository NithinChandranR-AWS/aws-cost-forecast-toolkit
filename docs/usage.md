# 🎯 Usage Examples

This guide provides comprehensive examples of how to use the AWS Cost Forecast Toolkit for various scenarios and use cases.

## 🚀 Quick Start Examples

### Basic Forecast Generation
```bash
# Simple interactive forecast
./scripts/forecast-data-fetch.sh

# Follow the prompts to:
# 1. Select time period (30, 90, 180, 365 days)
# 2. Choose metrics (AMORTIZED_COST, BLENDED_COST, etc.)
# 3. Select dimensions (SERVICE, REGION, ACCOUNT)
# 4. Configure S3 storage (optional)
```

### Command Line Usage
```bash
# Generate 90-day forecast with specific parameters
./scripts/forecast-data-fetch.sh \
  --start-date 2024-01-01 \
  --end-date 2024-03-31 \
  --bucket my-cost-forecasts \
  --region us-east-1

# Dry run to validate configuration
./scripts/forecast-data-fetch.sh --dry-run

# Show help and all options
./scripts/forecast-data-fetch.sh --help
```

## 📊 Business Use Cases

### 1. Monthly Budget Planning
Generate monthly cost forecasts for budget planning meetings:

```bash
# 30-day detailed forecast
./scripts/forecast-data-fetch.sh
# Select: 1) Next 30 days
# Select: 0) All metrics
# Select: 99) Recommended dimensions (SERVICE, REGION, LINKED_ACCOUNT)
# Select: 1) DAILY granularity
```

**Output**: Detailed daily breakdown by service and region for the next 30 days.

### 2. Quarterly Financial Planning
Create quarterly forecasts for financial planning:

```bash
# 90-day forecast for quarterly planning
./scripts/forecast-data-fetch.sh
# Select: 2) Next 90 days
# Select: 1,2) AMORTIZED_COST, BLENDED_COST
# Select: 8,7,3) SERVICE, REGION, LINKED_ACCOUNT
# Select: 2) MONTHLY granularity
```

**Use Case**: Present to CFO/Finance team for quarterly budget reviews.

### 3. Annual Budget Forecasting
Generate annual cost projections:

```bash
# Annual forecast with custom date range
./scripts/forecast-data-fetch.sh \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --bucket annual-forecasts-2024
```

**Output**: 12-month cost projection for annual budget planning.

### 4. Multi-Account Cost Analysis
Analyze costs across multiple AWS accounts:

```bash
# Focus on account-level breakdown
./scripts/forecast-data-fetch.sh
# Select: 3) Next 180 days
# Select: 1,2) AMORTIZED_COST, BLENDED_COST
# Select: 3,4) LINKED_ACCOUNT, LINKED_ACCOUNT_NAME
# Select: 2) MONTHLY granularity
```

**Use Case**: Understand cost distribution across business units or environments.

## 🎨 Dashboard Creation Examples

### Basic Dashboard Setup
```bash
# Create QuickSight dashboard from existing data
./scripts/quicksight-dashboard.sh \
  --bucket my-cost-forecasts \
  --region us-east-1

# Manual setup with step-by-step instructions
./scripts/quicksight-dashboard.sh --manual
```

### Advanced Dashboard Configuration
```bash
# Automated dashboard creation
./scripts/quicksight-dashboard.sh \
  --bucket enterprise-forecasts \
  --region us-west-2 \
  --auto-create
```

## 📈 Advanced Usage Scenarios

### 1. Service-Specific Analysis
Focus on specific AWS services:

```bash
# EC2 cost forecasting
./scripts/forecast-data-fetch.sh
# Select: 2) Next 90 days
# Select: 1) AMORTIZED_COST
# Select: 8,2) SERVICE, INSTANCE_TYPE
# Select: 1) DAILY granularity

# Then filter results for EC2 in your analysis
```

### 2. Regional Cost Optimization
Analyze costs by AWS region:

```bash
# Regional cost breakdown
./scripts/forecast-data-fetch.sh
# Select: 3) Next 180 days
# Select: 1,2) AMORTIZED_COST, BLENDED_COST
# Select: 7,8) REGION, SERVICE
# Select: 2) MONTHLY granularity
```

**Use Case**: Identify opportunities for regional cost optimization.

### 3. Reserved Instance Planning
Analyze usage patterns for RI planning:

```bash
# RI and usage analysis
./scripts/forecast-data-fetch.sh
# Select: 4) Next 365 days
# Select: 1,6) AMORTIZED_COST, USAGE_QUANTITY
# Select: 2,6,8) INSTANCE_TYPE, PURCHASE_TYPE, SERVICE
# Select: 2) MONTHLY granularity
```

**Output**: Data to inform Reserved Instance purchase decisions.

## 🔄 Automation Examples

### 1. Daily Automated Forecasts
Set up daily forecast generation:

```bash
# Create cron job for daily forecasts
crontab -e

# Add this line for daily 6 AM execution:
0 6 * * * cd /path/to/aws-cost-forecast-toolkit && ./scripts/forecast-data-fetch.sh --start-date $(date +%Y-%m-%d) --end-date $(date -d '+30 days' +%Y-%m-%d) --bucket daily-forecasts > /var/log/cost-forecast.log 2>&1
```

### 2. Weekly Executive Reports
Generate weekly reports for executives:

```bash
#!/bin/bash
# weekly-forecast.sh

# Generate weekly forecast
./scripts/forecast-data-fetch.sh \
  --start-date $(date +%Y-%m-%d) \
  --end-date $(date -d '+90 days' +%Y-%m-%d) \
  --bucket executive-reports

# Create dashboard
./scripts/quicksight-dashboard.sh \
  --bucket executive-reports \
  --auto-create

# Send notification (customize as needed)
echo "Weekly cost forecast generated" | mail -s "AWS Cost Forecast Ready" exec-team@company.com
```

### 3. Monthly Budget Alerts
Set up monthly budget validation:

```bash
#!/bin/bash
# monthly-budget-check.sh

# Generate monthly forecast
FORECAST_FILE=$(./scripts/forecast-data-fetch.sh \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date -d '+1 month' +%Y-%m-01) \
  --bucket budget-alerts | grep "Output file:" | cut -d: -f2)

# Analyze forecast vs budget (custom logic)
TOTAL_FORECAST=$(awk -F, 'NR>1 {sum+=$6} END {print sum}' "$FORECAST_FILE")
BUDGET_THRESHOLD=10000

if (( $(echo "$TOTAL_FORECAST > $BUDGET_THRESHOLD" | bc -l) )); then
    echo "WARNING: Forecast ($TOTAL_FORECAST) exceeds budget ($BUDGET_THRESHOLD)"
    # Send alert
fi
```

## 📊 Data Analysis Examples

### 1. CSV Data Processing
Process generated CSV files:

```bash
# Find top 10 most expensive services
head -1 output/latest/forecast_*.csv > top_services.csv
grep "SERVICE" output/latest/forecast_*.csv | \
  awk -F, '{sum[$2]+=$6} END {for(i in sum) print sum[i]","i}' | \
  sort -nr | head -10 >> top_services.csv

# Calculate monthly totals
awk -F, 'NR>1 {
  month=substr($4,1,7); 
  sum[month]+=$6
} END {
  for(m in sum) print m","sum[m]
}' output/latest/forecast_*.csv | sort
```

### 2. Cost Trend Analysis
Analyze cost trends over time:

```bash
# Extract daily cost trends
awk -F, 'NR>1 && $3=="AMORTIZED_COST" {
  date=$4; 
  sum[date]+=$6
} END {
  for(d in sum) print d","sum[d]
}' output/latest/forecast_*.csv | sort > daily_trends.csv

# Calculate week-over-week growth
# (Add custom analysis logic)
```

### 3. Service Cost Distribution
Analyze cost distribution by service:

```bash
# Service cost percentage
awk -F, 'NR>1 && $1=="SERVICE" {
  service[$2]+=$6; 
  total+=$6
} END {
  for(s in service) 
    printf "%s,%.2f,%.1f%%\n", s, service[s], (service[s]/total)*100
}' output/latest/forecast_*.csv | sort -t, -k2 -nr
```

## 🎯 Integration Examples

### 1. Slack Integration
Send forecast summaries to Slack:

```bash
#!/bin/bash
# slack-forecast-notification.sh

# Generate forecast
FORECAST_OUTPUT=$(./scripts/forecast-data-fetch.sh --quiet)
TOTAL_COST=$(echo "$FORECAST_OUTPUT" | grep "Total forecasted cost" | cut -d: -f2)

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"📊 Monthly AWS Cost Forecast: $TOTAL_COST\"}" \
  YOUR_SLACK_WEBHOOK_URL
```

### 2. Email Reports
Generate and email forecast reports:

```bash
#!/bin/bash
# email-forecast-report.sh

# Generate forecast
./scripts/forecast-data-fetch.sh \
  --start-date $(date +%Y-%m-%d) \
  --end-date $(date -d '+30 days' +%Y-%m-%d) \
  --bucket email-reports

# Create summary
LATEST_FILE=$(ls -t output/*/forecast_*.csv | head -1)
TOTAL_FORECAST=$(awk -F, 'NR>1 {sum+=$6} END {printf "%.2f", sum}' "$LATEST_FILE")

# Email report
{
  echo "Subject: AWS Cost Forecast Report"
  echo "Content-Type: text/html"
  echo ""
  echo "<h2>AWS Cost Forecast Summary</h2>"
  echo "<p>Total 30-day forecast: \$${TOTAL_FORECAST}</p>"
  echo "<p>Detailed report attached.</p>"
} | sendmail -t finance@company.com < "$LATEST_FILE"
```

### 3. Terraform Integration
Use forecasts in Terraform for budget alerts:

```hcl
# terraform/budget-alerts.tf
resource "aws_budgets_budget" "forecast_based_budget" {
  name         = "forecast-based-budget"
  budget_type  = "COST"
  limit_amount = var.forecast_amount  # From forecast data
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Service = ["Amazon Elastic Compute Cloud - Compute"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["finance@company.com"]
  }
}
```

## 🔧 Configuration Examples

### 1. Custom Configuration File
Create a custom configuration:

```bash
# config/production.conf
DEFAULT_BUCKET="production-cost-forecasts"
DEFAULT_REGION="us-east-1"
EMAIL_NOTIFICATIONS="finance@company.com"
QUICKSIGHT_AUTO_CREATE="true"
DEFAULT_FORECAST_DAYS="90"
DEFAULT_GRANULARITY="MONTHLY"
MAX_PARALLEL_JOBS="15"
DEBUG_LOGGING="false"

# Use custom configuration
export FORECAST_CONFIG="config/production.conf"
./scripts/forecast-data-fetch.sh
```

### 2. Environment-Specific Settings
Set up different environments:

```bash
# Development environment
export FORECAST_DEFAULT_BUCKET="dev-cost-forecasts"
export FORECAST_DEFAULT_REGION="us-west-2"
export FORECAST_DEBUG="true"

# Production environment
export FORECAST_DEFAULT_BUCKET="prod-cost-forecasts"
export FORECAST_DEFAULT_REGION="us-east-1"
export FORECAST_EMAIL_REPORTS="ops@company.com"
export FORECAST_MAX_PARALLEL="20"
```

## 📋 Best Practices

### 1. Regular Forecast Schedule
```bash
# Weekly comprehensive forecast
0 8 * * 1 /path/to/forecast-weekly.sh

# Daily quick forecast
0 6 * * * /path/to/forecast-daily.sh

# Monthly detailed analysis
0 9 1 * * /path/to/forecast-monthly.sh
```

### 2. Data Retention Strategy
```bash
#!/bin/bash
# cleanup-old-forecasts.sh

# Keep last 30 days of forecasts
find output/ -name "forecast_*.csv" -mtime +30 -delete

# Archive monthly reports
find output/ -name "forecast_*.csv" -mtime +7 -mtime -30 -exec gzip {} \;
```

### 3. Error Handling
```bash
#!/bin/bash
# robust-forecast.sh

set -euo pipefail

# Function to handle errors
handle_error() {
    echo "Error occurred in forecast generation"
    # Send alert
    echo "Forecast failed at $(date)" | mail -s "Forecast Error" ops@company.com
    exit 1
}

trap handle_error ERR

# Run forecast with error handling
./scripts/forecast-data-fetch.sh "$@"
```

## 🚨 Troubleshooting Examples

### Common Issues and Solutions

#### Large Dataset Handling
```bash
# For large accounts, use selective dimensions
./scripts/forecast-data-fetch.sh
# Select fewer dimensions to reduce API calls
# Use MONTHLY granularity for longer periods
# Consider running during off-peak hours
```

#### API Rate Limiting
```bash
# Increase delays between API calls
export FORECAST_API_DELAY="1.0"  # 1 second delay
./scripts/forecast-data-fetch.sh
```

#### Memory Issues
```bash
# Reduce parallel processing
export FORECAST_MAX_PARALLEL="5"
./scripts/forecast-data-fetch.sh
```

---

**Next Steps**: Check out our [Configuration Guide](configuration.md) for advanced customization options.
