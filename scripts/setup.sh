#!/bin/bash
# AWS Cost Forecast Toolkit Setup Script
# Author: Nithin Chandran R (rajashan@amazon.com)
# License: MIT
# Version: 2.0.0

# Set strict error handling
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly BG_BLUE='\033[44m'

# Display functions
display_banner() {
    local text="$1"
    local width=70
    local padding=$(( (width - ${#text}) / 2 ))
    
    echo
    echo -e "${BG_BLUE}${BOLD}$(printf '%*s' $width '')${NC}"
    echo -e "${BG_BLUE}${BOLD}$(printf '%*s' $padding '')${text}$(printf '%*s' $padding '')${NC}"
    echo -e "${BG_BLUE}${BOLD}$(printf '%*s' $width '')${NC}"
    echo
}

display_section_header() {
    local text="$1"
    echo -e "\n${YELLOW}${BOLD}═══════════════════ ${text} ═══════════════════${NC}\n"
}

log() {
    local level=$1
    local message=$2
    local color
    
    case $level in
        "INFO") color="${CYAN}";;
        "SUCCESS") color="${GREEN}";;
        "WARNING") color="${YELLOW}";;
        "ERROR") color="${RED}";;
        *) color="${NC}";;
    esac
    
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${color}${level}${NC}] ${message}"
}

# Check if running in CloudShell
check_cloudshell() {
    if [[ -n "${AWS_EXECUTION_ENV:-}" ]] && [[ "${AWS_EXECUTION_ENV}" == *"CloudShell"* ]]; then
        log "SUCCESS" "Running in AWS CloudShell - optimal environment detected"
        CLOUDSHELL=true
    else
        log "INFO" "Not running in CloudShell - will check local dependencies"
        CLOUDSHELL=false
    fi
}

# Check prerequisites
check_prerequisites() {
    display_section_header "CHECKING PREREQUISITES"
    local errors=0
    local warnings=0
    
    # Check bash version
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        log "WARNING" "Bash version ${BASH_VERSION} detected. Version 4+ recommended"
        warnings=$((warnings + 1))
    else
        log "SUCCESS" "Bash version ${BASH_VERSION} - compatible"
    fi
    
    # Check AWS CLI
    if ! command -v aws >/dev/null 2>&1; then
        log "ERROR" "AWS CLI is not installed"
        errors=$((errors + 1))
        
        if [[ "${CLOUDSHELL}" == "false" ]]; then
            echo -e "${YELLOW}Install AWS CLI:${NC}"
            echo -e "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
            echo -e "unzip awscliv2.zip && sudo ./aws/install"
        fi
    else
        local aws_version=$(aws --version 2>&1 | head -n1)
        log "SUCCESS" "AWS CLI found: ${aws_version}"
    fi
    
    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        log "ERROR" "jq is not installed"
        errors=$((errors + 1))
        
        if [[ "${CLOUDSHELL}" == "false" ]]; then
            echo -e "${YELLOW}Install jq:${NC}"
            echo -e "sudo apt-get update && sudo apt-get install -y jq  # Ubuntu/Debian"
            echo -e "sudo yum install -y jq                            # Amazon Linux/RHEL"
            echo -e "brew install jq                                   # macOS"
        fi
    else
        local jq_version=$(jq --version)
        log "SUCCESS" "jq found: ${jq_version}"
    fi
    
    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        log "WARNING" "curl is not installed (optional but recommended)"
        warnings=$((warnings + 1))
    else
        log "SUCCESS" "curl found"
    fi
    
    # Check git
    if ! command -v git >/dev/null 2>&1; then
        log "WARNING" "git is not installed (optional for development)"
        warnings=$((warnings + 1))
    else
        log "SUCCESS" "git found"
    fi
    
    # Summary
    if [ $errors -gt 0 ]; then
        log "ERROR" "Prerequisites check failed with ${errors} errors"
        if [[ "${CLOUDSHELL}" == "true" ]]; then
            log "ERROR" "This shouldn't happen in CloudShell. Please contact support."
        fi
        return 1
    elif [ $warnings -gt 0 ]; then
        log "WARNING" "Prerequisites check completed with ${warnings} warnings"
        log "INFO" "The toolkit will work but some features may be limited"
    else
        log "SUCCESS" "All prerequisites met"
    fi
    
    return 0
}

# Check AWS credentials and permissions
check_aws_access() {
    display_section_header "CHECKING AWS ACCESS"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log "ERROR" "AWS credentials not configured"
        echo -e "${YELLOW}Configure AWS credentials:${NC}"
        echo -e "aws configure                    # Interactive setup"
        echo -e "export AWS_PROFILE=your-profile  # Use specific profile"
        return 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local user_arn=$(aws sts get-caller-identity --query Arn --output text)
    local region=$(aws configure get region || echo "not-set")
    
    log "SUCCESS" "AWS credentials configured"
    log "INFO" "Account ID: ${account_id}"
    log "INFO" "User/Role: ${user_arn}"
    log "INFO" "Default Region: ${region}"
    
    # Check Cost Explorer permissions
    log "INFO" "Checking Cost Explorer permissions..."
    if aws ce get-cost-and-usage \
        --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --granularity DAILY \
        --metrics BlendedCost >/dev/null 2>&1; then
        log "SUCCESS" "Cost Explorer access confirmed"
    else
        log "WARNING" "Cost Explorer access may be limited"
        log "INFO" "Required permissions: ce:GetCostAndUsage, ce:GetCostForecast, ce:GetDimensionValues"
    fi
    
    # Check S3 permissions (basic)
    log "INFO" "Checking S3 permissions..."
    if aws s3 ls >/dev/null 2>&1; then
        log "SUCCESS" "S3 access confirmed"
    else
        log "WARNING" "S3 access may be limited"
        log "INFO" "S3 permissions needed for data storage and QuickSight integration"
    fi
    
    # Check QuickSight (optional)
    log "INFO" "Checking QuickSight access..."
    if aws quicksight describe-account-settings >/dev/null 2>&1; then
        log "SUCCESS" "QuickSight access confirmed"
    else
        log "INFO" "QuickSight not activated or accessible (optional feature)"
    fi
    
    return 0
}

# Make scripts executable
setup_scripts() {
    display_section_header "SETTING UP SCRIPTS"
    
    local script_dir="$(dirname "$0")"
    local scripts=(
        "forecast-data-fetch.sh"
        "quicksight-dashboard.sh"
        "setup.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="${script_dir}/${script}"
        if [[ -f "${script_path}" ]]; then
            chmod +x "${script_path}"
            log "SUCCESS" "Made ${script} executable"
        else
            log "WARNING" "Script not found: ${script}"
        fi
    done
    
    # Check if scripts are in PATH or provide instructions
    if [[ ":$PATH:" == *":$(pwd)/scripts:"* ]]; then
        log "SUCCESS" "Scripts directory is in PATH"
    else
        log "INFO" "To run scripts from anywhere, add to PATH:"
        echo -e "${CYAN}export PATH=\$PATH:$(pwd)/scripts${NC}"
    fi
}

# Create sample configuration
create_sample_config() {
    display_section_header "CREATING SAMPLE CONFIGURATION"
    
    local config_dir="$(dirname "$0")/../config"
    mkdir -p "${config_dir}"
    
    # Create sample user configuration
    local user_config="${config_dir}/user.conf.sample"
    cat > "${user_config}" << 'EOF'
# AWS Cost Forecast Toolkit - User Configuration
# Copy this file to user.conf and customize as needed

# Default S3 bucket for storing forecast data
DEFAULT_BUCKET=""

# Default AWS region
DEFAULT_REGION="us-east-1"

# Email for notifications (if supported)
EMAIL_NOTIFICATIONS=""

# QuickSight auto-creation (true/false)
QUICKSIGHT_AUTO_CREATE="false"

# Default forecast period in days
DEFAULT_FORECAST_DAYS="90"

# Default granularity (DAILY/MONTHLY)
DEFAULT_GRANULARITY="DAILY"

# Maximum parallel processes
MAX_PARALLEL_JOBS="10"

# Enable debug logging (true/false)
DEBUG_LOGGING="false"
EOF
    
    log "SUCCESS" "Created sample configuration: ${user_config}"
    log "INFO" "Copy to user.conf and customize as needed"
    
    # Create metrics configuration
    local metrics_config="${config_dir}/metrics.json"
    cat > "${metrics_config}" << 'EOF'
{
    "metrics": [
        {
            "name": "AMORTIZED_COST",
            "description": "Amortized cost including Reserved Instances and Savings Plans",
            "recommended": true
        },
        {
            "name": "BLENDED_COST",
            "description": "Blended cost across linked accounts",
            "recommended": true
        },
        {
            "name": "NET_AMORTIZED_COST",
            "description": "Net amortized cost after credits and refunds",
            "recommended": false
        },
        {
            "name": "NET_UNBLENDED_COST",
            "description": "Net unblended cost after credits and refunds",
            "recommended": false
        },
        {
            "name": "UNBLENDED_COST",
            "description": "Actual cost without blending",
            "recommended": true
        },
        {
            "name": "USAGE_QUANTITY",
            "description": "Usage quantity metrics",
            "recommended": false
        },
        {
            "name": "NORMALIZED_USAGE_AMOUNT",
            "description": "Normalized usage amount",
            "recommended": false
        }
    ]
}
EOF
    
    log "SUCCESS" "Created metrics configuration: ${metrics_config}"
    
    # Create dimensions configuration
    local dimensions_config="${config_dir}/dimensions.json"
    cat > "${dimensions_config}" << 'EOF'
{
    "dimensions": [
        {
            "name": "SERVICE",
            "description": "AWS Service breakdown",
            "recommended": true,
            "category": "service"
        },
        {
            "name": "REGION",
            "description": "AWS Region breakdown",
            "recommended": true,
            "category": "location"
        },
        {
            "name": "LINKED_ACCOUNT",
            "description": "Linked account breakdown",
            "recommended": true,
            "category": "account"
        },
        {
            "name": "INSTANCE_TYPE",
            "description": "EC2 instance type breakdown",
            "recommended": false,
            "category": "resource"
        },
        {
            "name": "USAGE_TYPE",
            "description": "Usage type breakdown",
            "recommended": false,
            "category": "usage"
        }
    ]
}
EOF
    
    log "SUCCESS" "Created dimensions configuration: ${dimensions_config}"
}

# Create output directory
setup_output_directory() {
    display_section_header "SETTING UP OUTPUT DIRECTORY"
    
    local output_dir="$(dirname "$0")/../output"
    mkdir -p "${output_dir}"
    
    # Create .gitignore for output directory
    cat > "${output_dir}/.gitignore" << 'EOF'
# Ignore all forecast output files
*.csv
*.json
*.log
**/temp/
**/cache/

# Keep directory structure
!.gitignore
!README.md
EOF
    
    # Create README for output directory
    cat > "${output_dir}/README.md" << 'EOF'
# Output Directory

This directory contains the generated forecast data and logs from the AWS Cost Forecast Toolkit.

## Directory Structure

```
output/
├── YYYYMMDD_HHMMSS/          # Timestamped run directories
│   ├── forecast_*.csv        # Generated forecast data
│   ├── forecast_*.log        # Execution logs
│   ├── quicksight-manifest.json  # QuickSight manifest
│   └── temp/                 # Temporary files (auto-cleaned)
└── README.md                 # This file
```

## File Formats

### CSV Output
- **Dimension**: The AWS dimension being analyzed (SERVICE, REGION, etc.)
- **Value**: The specific value for that dimension (e.g., "Amazon EC2")
- **Metric**: The cost metric (AMORTIZED_COST, BLENDED_COST, etc.)
- **StartDate/EndDate**: Time period for the forecast
- **MeanValue**: Forecasted cost value
- **LowerBound/UpperBound**: 95% confidence interval

### Log Files
- Timestamped execution logs with INFO, WARNING, ERROR levels
- Useful for debugging and monitoring script execution

## Data Retention

- Output files are not automatically cleaned up
- Consider implementing a retention policy for old forecast data
- Log files can grow large with verbose logging enabled
EOF
    
    log "SUCCESS" "Created output directory: ${output_dir}"
    log "INFO" "Forecast data and logs will be stored here"
}

# Display usage information
show_usage() {
    echo -e "${BOLD}AWS Cost Forecast Toolkit Setup v${SCRIPT_VERSION}${NC}"
    echo
    echo -e "${BOLD}USAGE:${NC}"
    echo "  $0 [OPTIONS]"
    echo
    echo -e "${BOLD}OPTIONS:${NC}"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  --check-only            Only check prerequisites, don't setup"
    echo "  --skip-aws              Skip AWS access checks"
    echo
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "  $0                      # Full setup"
    echo "  $0 --check-only         # Check prerequisites only"
    echo "  $0 --skip-aws           # Setup without AWS checks"
    echo
}

# Parse command line arguments
parse_arguments() {
    CHECK_ONLY=false
    SKIP_AWS=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "AWS Cost Forecast Toolkit Setup v${SCRIPT_VERSION}"
                exit 0
                ;;
            --check-only)
                CHECK_ONLY=true
                shift
                ;;
            --skip-aws)
                SKIP_AWS=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main execution function
main() {
    parse_arguments "$@"
    
    clear
    display_banner "AWS Cost Forecast Toolkit Setup v${SCRIPT_VERSION}"
    
    log "INFO" "Starting toolkit setup"
    log "INFO" "Version: ${SCRIPT_VERSION}"
    
    # Check environment
    check_cloudshell
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "ERROR" "Setup failed due to missing prerequisites"
        exit 1
    fi
    
    # Check AWS access unless skipped
    if [[ "${SKIP_AWS}" == "false" ]]; then
        if ! check_aws_access; then
            log "ERROR" "Setup failed due to AWS access issues"
            exit 1
        fi
    else
        log "INFO" "Skipping AWS access checks"
    fi
    
    # Exit if check-only mode
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        log "SUCCESS" "Prerequisites check completed"
        exit 0
    fi
    
    # Setup scripts and configuration
    setup_scripts
    create_sample_config
    setup_output_directory
    
    # Final summary
    display_section_header "SETUP COMPLETE"
    echo -e "${GREEN}${BOLD}✅ AWS Cost Forecast Toolkit Setup Complete!${NC}"
    echo
    echo -e "${CYAN}${BOLD}Next Steps:${NC}"
    echo -e "1. Review and customize configuration files in config/"
    echo -e "2. Run the main forecast tool:"
    echo -e "   ${BOLD}./scripts/forecast-data-fetch.sh${NC}"
    echo -e "3. Create QuickSight dashboards:"
    echo -e "   ${BOLD}./scripts/quicksight-dashboard.sh${NC}"
    echo
    echo -e "${YELLOW}${BOLD}Quick Start:${NC}"
    echo -e "cd $(dirname "$0")/.."
    echo -e "./scripts/forecast-data-fetch.sh"
    echo
    echo -e "${CYAN}${BOLD}Documentation:${NC}"
    echo -e "• README.md - Main documentation"
    echo -e "• docs/ - Detailed guides and examples"
    echo -e "• config/ - Configuration templates"
    echo
    
    if [[ "${CLOUDSHELL}" == "true" ]]; then
        echo -e "${GREEN}${BOLD}🎉 Perfect! You're running in AWS CloudShell${NC}"
        echo -e "All dependencies are pre-installed and ready to use!"
    else
        echo -e "${YELLOW}${BOLD}💡 Tip: Consider using AWS CloudShell${NC}"
        echo -e "It provides a pre-configured environment with all tools installed."
    fi
}

# Execute main function
main "$@"
