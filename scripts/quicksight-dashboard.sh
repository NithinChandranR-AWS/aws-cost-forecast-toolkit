#!/bin/bash
# AWS QuickSight Dashboard Creation Tool - CloudShell Edition
# Author: Nithin Chandran R (rajashan@amazon.com)
# License: MIT
# Version: 2.0.0

# Set strict error handling
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Color codes for better UX
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[1;35m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly BG_BLUE='\033[44m'

# Spinner characters
readonly SPINNER_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
declare -i spinner_idx=0

# Display functions
display_spinner() {
    local text="$1"
    printf "\r${CYAN}${SPINNER_CHARS:spinner_idx++:1}${NC} %s" "$text"
    spinner_idx=$(( spinner_idx >= ${#SPINNER_CHARS} ? 0 : spinner_idx ))
}

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

# Check prerequisites
check_prerequisites() {
    display_section_header "CHECKING PREREQUISITES"
    local errors=0
    
    # Check AWS CLI
    display_spinner "Checking AWS CLI..."
    if ! command -v aws >/dev/null 2>&1; then
        echo
        log "ERROR" "AWS CLI is not installed"
        errors=$((errors + 1))
    else
        echo
        log "SUCCESS" "AWS CLI found"
    fi
    
    # Check AWS credentials
    display_spinner "Checking AWS credentials..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo
        log "ERROR" "AWS credentials not configured"
        errors=$((errors + 1))
    else
        echo
        log "SUCCESS" "AWS credentials configured"
    fi
    
    # Check QuickSight access
    display_spinner "Checking QuickSight access..."
    if ! aws quicksight describe-account-settings >/dev/null 2>&1; then
        echo
        log "WARNING" "QuickSight may not be activated or accessible"
        log "INFO" "You may need to activate QuickSight first"
    else
        echo
        log "SUCCESS" "QuickSight access confirmed"
    fi
    
    if [ $errors -gt 0 ]; then
        log "ERROR" "Prerequisites check failed"
        exit 1
    fi
}

# Get account information
get_account_info() {
    display_section_header "ACCOUNT INFORMATION"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    CURRENT_REGION=$(aws configure get region || echo "us-east-1")
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    
    log "INFO" "AWS Account ID: ${ACCOUNT_ID}"
    log "INFO" "Current Region: ${CURRENT_REGION}"
    log "INFO" "User/Role: ${USER_ARN}"
    
    # Ask for region confirmation
    echo -e "\n${YELLOW}Use region ${CURRENT_REGION} for QuickSight? (y/N)${NC}"
    read -p "→ " use_region
    
    if [[ ${use_region,,} != "y" ]]; then
        echo -e "\n${CYAN}Enter desired region (e.g., us-east-1):${NC}"
        read -p "→ " REGION
    else
        REGION=$CURRENT_REGION
    fi
    
    log "SUCCESS" "Using region: ${REGION}"
}

# Get S3 manifest information
get_manifest_info() {
    display_section_header "S3 MANIFEST CONFIGURATION"
    
    echo -e "${CYAN}${BOLD}Enter S3 bucket name containing your forecast data:${NC}"
    read -p "→ " S3_BUCKET
    
    if [[ -z "${S3_BUCKET}" ]]; then
        log "ERROR" "S3 bucket name is required"
        exit 1
    fi
    
    # Validate bucket access
    display_spinner "Validating S3 bucket access..."
    if ! aws s3 ls "s3://${S3_BUCKET}" >/dev/null 2>&1; then
        echo
        log "ERROR" "Cannot access S3 bucket: ${S3_BUCKET}"
        exit 1
    fi
    
    echo
    log "SUCCESS" "S3 bucket access validated"
    
    # Check for existing manifest
    MANIFEST_URI="s3://${S3_BUCKET}/forecasts/quicksight-manifest.json"
    
    display_spinner "Checking for existing QuickSight manifest..."
    if aws s3 ls "${MANIFEST_URI}" >/dev/null 2>&1; then
        echo
        log "SUCCESS" "Found existing QuickSight manifest"
        USE_EXISTING_MANIFEST=true
    else
        echo
        log "INFO" "No existing manifest found - will create one"
        USE_EXISTING_MANIFEST=false
        
        # Ask for CSV file location
        echo -e "\n${CYAN}Enter the S3 path to your forecast CSV file:${NC}"
        echo -e "${YELLOW}Example: s3://${S3_BUCKET}/forecasts/forecast_20240618_123456.csv${NC}"
        read -p "→ " CSV_S3_URI
        
        if [[ -z "${CSV_S3_URI}" ]]; then
            log "ERROR" "CSV S3 URI is required"
            exit 1
        fi
    fi
}

# Create QuickSight manifest if needed
create_manifest() {
    if [[ "${USE_EXISTING_MANIFEST}" == "true" ]]; then
        log "INFO" "Using existing manifest file"
        return 0
    fi
    
    display_section_header "CREATING QUICKSIGHT MANIFEST"
    
    local manifest_content=$(cat << EOF
{
    "fileLocations": [
        {
            "URIs": [
                "${CSV_S3_URI}"
            ]
        }
    ],
    "globalUploadSettings": {
        "format": "CSV",
        "delimiter": ",",
        "textqualifier": "\"",
        "containsHeader": "true"
    }
}
EOF
)
    
    # Create temporary manifest file
    local temp_manifest="/tmp/quicksight-manifest-${TIMESTAMP}.json"
    echo "${manifest_content}" > "${temp_manifest}"
    
    # Upload to S3
    display_spinner "Uploading QuickSight manifest to S3..."
    if aws s3 cp "${temp_manifest}" "${MANIFEST_URI}" >/dev/null 2>&1; then
        echo
        log "SUCCESS" "QuickSight manifest uploaded to ${MANIFEST_URI}"
        rm "${temp_manifest}"
    else
        echo
        log "ERROR" "Failed to upload manifest to S3"
        exit 1
    fi
}

# Create QuickSight data source
create_data_source() {
    display_section_header "CREATING QUICKSIGHT DATA SOURCE"
    
    local data_source_id="cost-forecast-s3-${TIMESTAMP}"
    local data_source_name="Cost Forecast S3 Data"
    
    display_spinner "Creating QuickSight data source..."
    
    # Create data source
    if aws quicksight create-data-source \
        --aws-account-id "${ACCOUNT_ID}" \
        --data-source-id "${data_source_id}" \
        --name "${data_source_name}" \
        --type S3 \
        --data-source-parameters "{
            \"S3Parameters\": {
                \"ManifestFileLocation\": {
                    \"Bucket\": \"${S3_BUCKET}\",
                    \"Key\": \"forecasts/quicksight-manifest.json\"
                }
            }
        }" \
        --region "${REGION}" >/dev/null 2>&1; then
        
        echo
        log "SUCCESS" "QuickSight data source created: ${data_source_id}"
        DATA_SOURCE_ARN="arn:aws:quicksight:${REGION}:${ACCOUNT_ID}:datasource/${data_source_id}"
    else
        echo
        log "ERROR" "Failed to create QuickSight data source"
        log "INFO" "This might be due to permissions or QuickSight not being properly configured"
        exit 1
    fi
}

# Create QuickSight dataset
create_dataset() {
    display_section_header "CREATING QUICKSIGHT DATASET"
    
    local dataset_id="cost-forecast-dataset-${TIMESTAMP}"
    local dataset_name="Cost Forecast Dataset"
    
    display_spinner "Creating QuickSight dataset..."
    
    # Create dataset configuration
    local dataset_config=$(cat << 'EOF'
{
    "PhysicalTableMap": {
        "cost_forecast_table": {
            "S3Source": {
                "DataSourceArn": "DATA_SOURCE_ARN_PLACEHOLDER",
                "InputColumns": [
                    {"Name": "Dimension", "Type": "STRING"},
                    {"Name": "Value", "Type": "STRING"},
                    {"Name": "Metric", "Type": "STRING"},
                    {"Name": "StartDate", "Type": "DATETIME"},
                    {"Name": "EndDate", "Type": "DATETIME"},
                    {"Name": "MeanValue", "Type": "DECIMAL"},
                    {"Name": "LowerBound", "Type": "DECIMAL"},
                    {"Name": "UpperBound", "Type": "DECIMAL"}
                ]
            }
        }
    },
    "LogicalTableMap": {
        "cost_forecast_logical": {
            "Alias": "CostForecast",
            "Source": {
                "PhysicalTableId": "cost_forecast_table"
            },
            "DataTransforms": [
                {
                    "CreateColumnsOperation": {
                        "Columns": [
                            {
                                "ColumnName": "MonthYear",
                                "ColumnId": "month_year",
                                "Expression": "formatDate({StartDate}, 'yyyy-MM')"
                            }
                        ]
                    }
                }
            ]
        }
    }
}
EOF
)
    
    # Replace placeholder with actual data source ARN
    dataset_config=$(echo "${dataset_config}" | sed "s|DATA_SOURCE_ARN_PLACEHOLDER|${DATA_SOURCE_ARN}|g")
    
    # Save to temporary file
    local temp_dataset_config="/tmp/dataset-config-${TIMESTAMP}.json"
    echo "${dataset_config}" > "${temp_dataset_config}"
    
    # Create dataset
    if aws quicksight create-data-set \
        --aws-account-id "${ACCOUNT_ID}" \
        --data-set-id "${dataset_id}" \
        --name "${dataset_name}" \
        --import-mode SPICE \
        --cli-input-json "file://${temp_dataset_config}" \
        --region "${REGION}" >/dev/null 2>&1; then
        
        echo
        log "SUCCESS" "QuickSight dataset created: ${dataset_id}"
        DATASET_ARN="arn:aws:quicksight:${REGION}:${ACCOUNT_ID}:dataset/${dataset_id}"
        rm "${temp_dataset_config}"
    else
        echo
        log "ERROR" "Failed to create QuickSight dataset"
        rm "${temp_dataset_config}"
        exit 1
    fi
}

# Provide manual setup instructions
provide_manual_instructions() {
    display_section_header "MANUAL SETUP INSTRUCTIONS"
    
    echo -e "${GREEN}${BOLD}🎯 QuickSight Dashboard Setup Instructions:${NC}"
    echo
    echo -e "${CYAN}${BOLD}Step 1: Access QuickSight${NC}"
    echo -e "1. Open AWS QuickSight in your browser:"
    echo -e "   ${UNDERLINE}https://${REGION}.quicksight.aws.amazon.com${NC}"
    echo -e "2. Sign in with your AWS credentials"
    echo
    
    echo -e "${CYAN}${BOLD}Step 2: Create Dataset${NC}"
    echo -e "1. Click 'Datasets' in the left navigation"
    echo -e "2. Click 'New dataset'"
    echo -e "3. Choose 'S3' as your data source"
    echo -e "4. Enter these details:"
    echo -e "   • Data source name: Cost Forecast Data"
    echo -e "   • Manifest file URL: ${BOLD}${MANIFEST_URI}${NC}"
    echo -e "5. Click 'Connect'"
    echo -e "6. Select 'Import to SPICE for quicker analytics'"
    echo -e "7. Click 'Visualize'"
    echo
    
    echo -e "${CYAN}${BOLD}Step 3: Create Visualizations${NC}"
    echo -e "1. ${BOLD}Cost Trend Over Time:${NC}"
    echo -e "   • Drag 'StartDate' to X-axis"
    echo -e "   • Drag 'MeanValue' to Y-axis"
    echo -e "   • Choose Line Chart"
    echo -e "   • Add 'Metric' to Color"
    echo
    echo -e "2. ${BOLD}Cost by Service:${NC}"
    echo -e "   • Filter 'Dimension' = 'SERVICE'"
    echo -e "   • Drag 'Value' to Group/Color"
    echo -e "   • Drag 'MeanValue' to Y-axis"
    echo -e "   • Choose Bar Chart"
    echo
    echo -e "3. ${BOLD}Forecast Confidence:${NC}"
    echo -e "   • Drag 'StartDate' to X-axis"
    echo -e "   • Drag 'MeanValue', 'LowerBound', 'UpperBound' to Y-axis"
    echo -e "   • Choose Line Chart"
    echo
    
    echo -e "${CYAN}${BOLD}Step 4: Create Dashboard${NC}"
    echo -e "1. Click 'Share' → 'Publish dashboard'"
    echo -e "2. Enter dashboard name: 'AWS Cost Forecast Dashboard'"
    echo -e "3. Click 'Publish dashboard'"
    echo -e "4. Set up permissions for your team"
    echo
    
    echo -e "${YELLOW}${BOLD}💡 Pro Tips:${NC}"
    echo -e "• Use filters to focus on specific services or time periods"
    echo -e "• Set up scheduled refresh to keep data current"
    echo -e "• Create calculated fields for cost per day/month"
    echo -e "• Add parameters for interactive filtering"
    echo -e "• Export visualizations for presentations"
    echo
    
    echo -e "${GREEN}${BOLD}📊 Key Metrics to Track:${NC}"
    echo -e "• Total forecasted cost (MeanValue sum)"
    echo -e "• Cost growth rate (month-over-month)"
    echo -e "• Service cost distribution"
    echo -e "• Regional cost breakdown"
    echo -e "• Forecast accuracy (compare with actual costs)"
}

# Display usage information
show_usage() {
    echo -e "${BOLD}AWS QuickSight Dashboard Creation Tool v${SCRIPT_VERSION}${NC}"
    echo
    echo -e "${BOLD}USAGE:${NC}"
    echo "  $0 [OPTIONS]"
    echo
    echo -e "${BOLD}OPTIONS:${NC}"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  --bucket BUCKET         S3 bucket containing forecast data"
    echo "  --region REGION         AWS region for QuickSight"
    echo "  --manual                Skip automated setup, show manual instructions only"
    echo
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "  $0                                    # Interactive mode"
    echo "  $0 --bucket my-forecasts --region us-east-1"
    echo "  $0 --manual                          # Manual setup instructions only"
    echo
}

# Parse command line arguments
parse_arguments() {
    MANUAL_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "AWS QuickSight Dashboard Creation Tool v${SCRIPT_VERSION}"
                exit 0
                ;;
            --bucket)
                S3_BUCKET="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --manual)
                MANUAL_ONLY=true
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
    display_banner "AWS QuickSight Dashboard Creation Tool v${SCRIPT_VERSION}"
    
    log "INFO" "Starting QuickSight Dashboard Creation"
    log "INFO" "Version: ${SCRIPT_VERSION}"
    
    if [[ "${MANUAL_ONLY}" == "true" ]]; then
        # Get basic info for manual instructions
        if [[ -z "${S3_BUCKET}" ]]; then
            echo -e "${CYAN}Enter S3 bucket name containing forecast data:${NC}"
            read -p "→ " S3_BUCKET
        fi
        
        if [[ -z "${REGION}" ]]; then
            REGION=$(aws configure get region || echo "us-east-1")
        fi
        
        MANIFEST_URI="s3://${S3_BUCKET}/forecasts/quicksight-manifest.json"
        provide_manual_instructions
        exit 0
    fi
    
    # Full automated setup
    check_prerequisites
    get_account_info
    get_manifest_info
    create_manifest
    
    # Try automated QuickSight setup
    echo -e "\n${YELLOW}Attempt automated QuickSight setup? (y/N)${NC}"
    echo -e "${CYAN}Note: This requires proper QuickSight permissions${NC}"
    read -p "→ " attempt_auto
    
    if [[ ${attempt_auto,,} == "y" ]]; then
        create_data_source
        create_dataset
        
        display_section_header "AUTOMATED SETUP COMPLETE"
        log "SUCCESS" "QuickSight data source and dataset created successfully"
        log "INFO" "Data Source ARN: ${DATA_SOURCE_ARN}"
        log "INFO" "Dataset ARN: ${DATASET_ARN}"
        echo
        echo -e "${GREEN}${BOLD}✅ Next Steps:${NC}"
        echo -e "1. Go to QuickSight and create a new analysis"
        echo -e "2. Use the created dataset to build visualizations"
        echo -e "3. Publish as a dashboard when ready"
    else
        log "INFO" "Skipping automated setup"
    fi
    
    # Always provide manual instructions
    provide_manual_instructions
    
    display_section_header "SETUP COMPLETE"
    echo -e "${GREEN}${BOLD}🎉 QuickSight Dashboard Setup Ready!${NC}"
    echo
    echo -e "${CYAN}Resources Created:${NC}"
    echo -e "• S3 Manifest: ${MANIFEST_URI}"
    if [[ -n "${DATA_SOURCE_ARN:-}" ]]; then
        echo -e "• QuickSight Data Source: ${DATA_SOURCE_ARN}"
        echo -e "• QuickSight Dataset: ${DATASET_ARN}"
    fi
    echo
    echo -e "${YELLOW}Access QuickSight at: ${UNDERLINE}https://${REGION}.quicksight.aws.amazon.com${NC}"
}

# Execute main function
main "$@"
