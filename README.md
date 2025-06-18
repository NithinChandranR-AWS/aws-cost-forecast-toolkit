# 🚀 AWS Cost Forecast Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![AWS](https://img.shields.io/badge/AWS-Cost%20Explorer-orange.svg)](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
[![QuickSight](https://img.shields.io/badge/AWS-QuickSight-blue.svg)](https://aws.amazon.com/quicksight/)

> **A powerful, CloudShell-ready toolkit for AWS cost forecasting with automated QuickSight dashboard creation**

Transform your AWS cost management with this comprehensive shell script toolkit that fetches cost forecast data, processes it efficiently, and creates beautiful QuickSight dashboards - all from AWS CloudShell!

## ✨ Features

🔮 **Advanced Cost Forecasting**
- Fetch forecasts for multiple AWS services simultaneously
- Support for all AWS Cost Explorer metrics (AMORTIZED_COST, BLENDED_COST, etc.)
- Parallel processing for faster data collection
- Configurable time periods (30, 90, 180, 365 days or custom)

📊 **Automated Dashboard Creation**
- One-click QuickSight dashboard generation
- Pre-built templates for cost analysis
- Interactive visualizations with drill-down capabilities
- Automated data refresh scheduling

☁️ **CloudShell Optimized**
- Zero installation required - runs directly in AWS CloudShell
- Built-in AWS CLI integration
- Intelligent error handling and recovery
- Progress indicators and colored output

🎯 **Enterprise Ready**
- Multi-account support
- Bulk data processing
- S3 integration for data storage
- Email reporting capabilities

## 🚀 Quick Start (30 seconds)

### Step 1: Open AWS CloudShell
1. Log into your AWS Console
2. Click the CloudShell icon (terminal) in the top navigation
3. Wait for CloudShell to initialize

### Step 2: Download and Run
```bash
# Clone the repository
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Make scripts executable
chmod +x scripts/*.sh

# Run the main forecast tool
./scripts/forecast-data-fetch.sh
```

### Step 3: Follow the Interactive Prompts
The script will guide you through:
- ✅ Time period selection
- ✅ Metrics and dimensions selection  
- ✅ S3 bucket configuration
- ✅ QuickSight dashboard creation

That's it! Your cost forecast data and dashboard will be ready in minutes.

## 📋 Prerequisites

✅ **AWS Account** with appropriate permissions  
✅ **AWS CloudShell** access (included with AWS account)  
✅ **Cost Explorer** enabled (free with AWS account)  
✅ **QuickSight** subscription (optional, for dashboards)  
✅ **S3 bucket** for data storage (optional)

> **Note**: All tools (AWS CLI, jq, bash) are pre-installed in CloudShell!

## 🎯 Use Cases

### 💼 **Business Planning**
- Monthly budget forecasting
- Quarterly cost projections
- Annual budget planning
- Service cost optimization

### 📈 **Cost Optimization**
- Identify cost trends and anomalies
- Compare forecasted vs actual costs
- Track Reserved Instance utilization
- Monitor service-level spending

### 📊 **Executive Reporting**
- Automated monthly cost reports
- Executive dashboard creation
- Stakeholder cost visibility
- Budget variance analysis

## 🛠️ Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `forecast-data-fetch.sh` | Main cost forecasting tool | `./scripts/forecast-data-fetch.sh` |
| `quicksight-dashboard.sh` | Dashboard creation automation | `./scripts/quicksight-dashboard.sh` |
| `setup.sh` | Environment setup and validation | `./scripts/setup.sh` |

## 📊 Sample Output

```csv
Dimension,Value,Metric,StartDate,EndDate,MeanValue,LowerBound,UpperBound
SERVICE,Amazon EC2,UNBLENDED_COST,2024-01-01,2024-01-02,125.50,120.00,131.00
SERVICE,Amazon S3,UNBLENDED_COST,2024-01-01,2024-01-02,45.25,42.00,48.50
SERVICE,Amazon RDS,UNBLENDED_COST,2024-01-01,2024-01-02,89.75,85.00,94.50
```

## 🎨 Dashboard Examples

### Cost Trend Analysis
![Cost Trend Dashboard](docs/assets/dashboard-trend.png)

### Service Breakdown
![Service Breakdown](docs/assets/dashboard-services.png)

### Forecast vs Actual
![Forecast vs Actual](docs/assets/dashboard-comparison.png)

## 📖 Documentation

- 📘 [Installation Guide](docs/installation.md)
- 🎯 [Usage Examples](docs/usage.md)
- 🔧 [Configuration Options](docs/configuration.md)
- 🐛 [Troubleshooting](docs/troubleshooting.md)
- 🤝 [Contributing](CONTRIBUTING.md)

## 🌟 Advanced Features

### Multi-Account Support
```bash
# Set up cross-account access
export AWS_PROFILE=production
./scripts/forecast-data-fetch.sh --account-id 123456789012
```

### Custom Time Periods
```bash
# Custom date range
./scripts/forecast-data-fetch.sh --start-date 2024-01-01 --end-date 2024-12-31
```

### Automated Scheduling
```bash
# Set up daily automated reports
./scripts/setup-automation.sh --schedule daily --email your@email.com
```

## 🔧 Configuration

### Environment Variables
```bash
# Optional: Set default configuration
export FORECAST_DEFAULT_BUCKET="my-cost-data-bucket"
export FORECAST_DEFAULT_REGION="us-east-1"
export FORECAST_EMAIL_REPORTS="admin@company.com"
```

### Configuration File
Create `config/user.conf` for persistent settings:
```bash
# Default settings
DEFAULT_BUCKET="my-cost-forecasts"
DEFAULT_REGION="us-east-1"
EMAIL_NOTIFICATIONS="true"
QUICKSIGHT_AUTO_CREATE="true"
```

## 🚨 Troubleshooting

### Common Issues

**❌ "AWS CLI not found"**
```bash
# This shouldn't happen in CloudShell, but if it does:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

**❌ "Permission denied"**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

**❌ "Cost Explorer access denied"**
- Ensure your IAM user/role has `ce:GetCostAndUsage` and `ce:GetCostForecast` permissions

**❌ "QuickSight not available"**
- QuickSight must be activated in your AWS account
- Ensure you have QuickSight permissions

## 🤝 Contributing

We welcome contributions from the AWS community! 

### Quick Contribution Guide
1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/amazing-feature`)
3. ✅ Test your changes in CloudShell
4. 📝 Commit your changes (`git commit -m 'Add amazing feature'`)
5. 🚀 Push to the branch (`git push origin feature/amazing-feature`)
6. 🎯 Open a Pull Request

### Development Setup
```bash
# Clone your fork
git clone https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit.git
cd aws-cost-forecast-toolkit

# Run tests
./tests/run-tests.sh

# Check script quality
shellcheck scripts/*.sh
```

## 📈 Roadmap

- [ ] **Multi-cloud support** (Azure, GCP cost forecasting)
- [ ] **Machine learning predictions** (trend analysis)
- [ ] **Slack/Teams integration** (automated notifications)
- [ ] **Terraform module** (infrastructure as code)
- [ ] **API Gateway wrapper** (REST API access)
- [ ] **Mobile dashboard** (responsive QuickSight templates)

## 🏆 Community

### Recognition
Special thanks to our contributors:
- 🌟 **Top Contributors**: [Will be updated as community grows]
- 🐛 **Bug Hunters**: [Community bug reporters]
- 📖 **Documentation Heroes**: [Documentation contributors]

### Get Involved
- 💬 [GitHub Discussions](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/discussions) - Ask questions, share ideas
- 🐛 [Report Issues](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues) - Found a bug? Let us know!
- 📧 [Email Updates](mailto:your-email@domain.com) - Stay updated on releases

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/NithinChandranR-AWS/aws-cost-forecast-toolkit?style=social)
![GitHub forks](https://img.shields.io/github/forks/NithinChandranR-AWS/aws-cost-forecast-toolkit?style=social)
![GitHub issues](https://img.shields.io/github/issues/NithinChandranR-AWS/aws-cost-forecast-toolkit)
![GitHub pull requests](https://img.shields.io/github/issues-pr/NithinChandranR-AWS/aws-cost-forecast-toolkit)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
1. 📖 Check the [documentation](docs/)
2. 🔍 Search [existing issues](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues)
3. 💬 Start a [discussion](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/discussions)
4. 🐛 [Create an issue](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues/new)

### Professional Support
For enterprise support, training, or custom implementations:
- 💼 LinkedIn: [Nithin Chandran R](https://www.linkedin.com/in/nithin-chandran-r/)
- � GitHub: [NithinChandranR-AWS](https://github.com/NithinChandranR-AWS)

---

<div align="center">

**⭐ If this tool helps you save money on AWS, please give it a star! ⭐**

Made with ❤️ for the AWS Community

[⬆ Back to Top](#-aws-cost-forecast-toolkit)

</div>
