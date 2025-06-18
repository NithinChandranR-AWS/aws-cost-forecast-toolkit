#!/bin/bash
# AWS Cost Forecast Data Fetch Tool - Enhanced Community Edition
# Author: Nithin Chandran R (rajashan@amazon.com)
# License: MIT
# Version: 2.0.0

# Set strict error handling
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly OUTPUT_DIR="${PWD}/output/${TIMESTAMP}"
readonly OUTPUT_FILE="${OUTPUT_DIR}/forecast_${TIMESTAMP}.csv"
readonly TEMP_DIR="${OUTPUT_DIR}/temp"
readonly LOG_FILE="${OUTPUT_DIR}/forecast_${TIMESTAMP}.log"
readonly MAX_PARALLEL=10  # Maximum parallel processes

# Create directories
mkdir -p "${OUTPUT_DIR}" "${TEMP_DIR}"

# Color codes and formatting for better UX
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[1;35m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly UNDERLINE='\033[4m'
readonly BG_BLUE='\033[44m'
readonly BG_GREEN='\033[42m'

# Spinner characters for loading animations
readonly SPINNER_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

# Global variables for job tracking
declare -i total_jobs=0
declare -i completed_jobs=0
declare -i spinner_idx=0
declare -i failed_jobs=0

# Available metrics (AWS Cost Explorer supported)
readonly METRICS=(
    "AMORTIZED_COST"
    "BLENDED_COST"
    "NET_AMORTIZED_COST"
    "NET_UNBLENDED_COST"
    "UNBLENDED_COST"
    "USAGE_QUANTITY"
    "NORMALIZED_USAGE_AMOUNT"
)

# Available dimensions (AWS Cost Explorer supported)
readonly DIMENSIONS=(
    "AZ"
    "INSTANCE_TYPE"
    "LINKED_ACCOUNT"
    "LINKED_ACCOUNT_NAME"
    "OPERATION"
    "PURCHASE_TYPE"
    "REGION"
    "SERVICE"
    "USAGE_TYPE"
    "USAGE_TYPE_GROUP"
    "RECORD_TYPE"
    "OPERATING_SYSTEM"
    "TENANCY"
    "SCOPE"
    "PLATFORM"
    "SUBSCRIPTION_ID"
    "LEGAL_ENTITY_NAME"
    "DEPLOYMENT_OPTION"
    "DATABASE_ENGINE"
    "INSTANCE_TYPE_FAMILY"
    "BILLING_ENTITY"
    "RESERVATION_ID"
    "SAVINGS_PLAN_ARN"
)

# Display functions for better user experience
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

display_progress_bar() {
    local progress=$1
    local text="${2:-Processing}"
    local width=40
    local filled=$(( progress * width / 100 ))
    local empty=$(( width - filled ))
    
    printf "\r${CYAN}${text}: ["
    printf "%${filled}s" '' | tr ' ' '█'
    printf "%${empty}s" '' | tr ' ' '░'
    printf "] %3d%% (${completed_jobs}/${total_jobs})${NC}" $progress
}

# Enhanced logging function
log() {
    local level=$1
    local message=$2
    local color
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") color="${CYAN}";;
        "SUCCESS") color="${GREEN}";;
        "WARNING") color="${YELLOW}";;
        "ERROR") color="${RED}";;
        "DEBUG") color="${MAGENTA}";;
        *) color="${NC}";;
    esac
    
    # Display to console
    echo -e "${timestamp} [${color}${level}${NC}] ${message}"
    
    # Log to file
    echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
}

# Rate limiting function to avoid AWS API throttling
rate_limit() {
    sleep 0.5  # Half second delay between API calls
}

# Enhanced prerequisite checking
check_prerequisites() {
    display_section_header "CHECKING PREREQUISITES"
    local spinner_text="Checking AWS CLI..."
    local errors=0
    
    display_spinner "${spinner_text}"
    if ! command -v aws >/dev/null 2>&1; then
        echo
        log "ERROR" "AWS CLI is not installed"
        errors=$((errors + 1))
    else
        echo
        log "SUCCESS" "AWS CLI found: $(aws --version | head -n1)"
    fi
    
    spinner_text="Checking jq..."
    display_spinner "${spinner_text}"
    if ! command -v jq >/dev/null 2>&1; then
        echo
        log "ERROR" "jq is not installed"
        errors=$((errors + 1))
    else
        echo
        log "SUCCESS" "jq found: $(jq --version)"
    fi
    
    spinner_text="Checking AWS credentials..."
    display_spinner "${spinner_text}"
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo
        log "ERROR" "AWS credentials not configured"
        errors=$((errors + 1))
    else
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        echo
        log "SUCCESS" "AWS credentials configured"
        log "INFO" "Account ID: ${account_id}"
        log "INFO" "User/Role: ${user_arn}"
    fi
    
    spinner_text="Checking Cost Explorer permissions..."
    display_spinner "${spinner_text}"
    if ! aws ce get-cost-and-usage --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity DAILY --metrics BlendedCost >/dev/null 2>&1; then
        echo
        log "WARNING" "Cost Explorer permissions may be limited"
        log "INFO" "Some features may not work without proper CE permissions"
    else
        echo
        log "SUCCESS" "Cost Explorer access confirmed"
    fi
    
    if [ $errors -gt 0 ]; then
        log "ERROR" "Prerequisites check failed with ${errors} errors"
        exit 1
    fi
    
    log "SUCCESS" "All prerequisites met"
}

# Enhanced time period selection with validation
get_time_period() {
    display_section_header "TIME PERIOD SELECTION"
    echo -e "${CYAN}${BOLD}Select Time Period for Forecast:${NC}"
    echo -e "${MAGENTA}1)${NC} Next 30 days (recommended for detailed analysis)"
    echo -e "${MAGENTA}2)${NC} Next 90 days (quarterly planning)"
    echo -e "${MAGENTA}3)${NC} Next 180 days (semi-annual planning)"
    echo -e "${MAGENTA}4)${NC} Next 365 days (annual planning)"
    echo -e "${MAGENTA}5)${NC} Custom period (specify your own dates)"
    
    echo -e "\n${BOLD}Enter your choice [1-5]:${NC}"
    read -p "→ " choice
    
    TODAY=$(date '+%Y-%m-%d')
    
    case $choice in
        1) 
            END_DATE=$(date -d "${TODAY} +30 days" '+%Y-%m-%d')
            log "INFO" "Selected: 30-day forecast period"
            ;;
        2) 
            END_DATE=$(date -d "${TODAY} +90 days" '+%Y-%m-%d')
            log "INFO" "Selected: 90-day forecast period"
            ;;
        3) 
            END_DATE=$(date -d "${TODAY} +180 days" '+%Y-%m-%d')
            log "INFO" "Selected: 180-day forecast period"
            ;;
        4) 
            END_DATE=$(date -d "${TODAY} +365 days" '+%Y-%m-%d')
            log "INFO" "Selected: 365-day forecast period"
            ;;
        5)
            echo -e "\n${BOLD}Enter end date (YYYY-MM-DD format):${NC}"
            read -p "→ " END_DATE
            
            # Validate date format
            if ! date -d "${END_DATE}" >/dev/null 2>&1; then
                log "ERROR" "Invalid date format. Please use YYYY-MM-DD"
                exit 1
            fi
            
            # Ensure end date is in the future
            if [[ "${END_DATE}" < "${TODAY}" ]]; then
                log "ERROR" "End date must be in the future"
                exit 1
            fi
            
            log "INFO" "Selected: Custom forecast period"
            ;;
        *)
            log "ERROR" "Invalid choice. Please select 1-5"
            exit 1
            ;;
    esac
    
    START_DATE="${TODAY}"
    TIME_PERIOD="Start=${START_DATE},End=${END_DATE}"
    
    # Calculate forecast duration
    local duration_days=$(( ($(date -d "${END_DATE}" +%s) - $(date -d "${START_DATE}" +%s)) / 86400 ))
    
    log "SUCCESS" "Time period configured:"
    log "INFO" "  Start Date: ${START_DATE}"
    log "INFO" "  End Date: ${END_DATE}"
    log "INFO" "  Duration: ${duration_days} days"
}

# Enhanced dimension value fetching with caching
get_dimension_values() {
    local dimension=$1
    local cache_file="${TEMP_DIR}/dimension_${dimension}.cache"
    local values
    
    # Check cache first (valid for 1 hour)
    if [[ -f "${cache_file}" ]] && [[ $(find "${cache_file}" -mmin -60) ]]; then
        log "DEBUG" "Using cached values for dimension: ${dimension}"
        cat "${cache_file}"
        return 0
    fi
    
    local spinner_text="Fetching values for ${dimension}..."
    display_spinner "${spinner_text}"
    
    rate_limit
    values=$(aws ce get-dimension-values \
        --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --dimension "${dimension}" \
        --query 'DimensionValues[*].Value' \
        --output json 2>/dev/null | jq -r '.[]' 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$values" ]]; then
        # Cache the results
        echo "$values" > "${cache_file}"
        echo "$values"
        echo
        log "SUCCESS" "Found $(echo "$values" | wc -l) values for dimension: ${dimension}"
    else
        echo
        log "WARNING" "No values found for dimension: ${dimension}"
        echo ""
    fi
}

# Enhanced forecast fetching with retry logic
fetch_forecast() {
    local dimension=$1
    local value=$2
    local metric=$3
    local output_file="${TEMP_DIR}/${dimension}_${value//\//_}_${metric}.json"
    local max_retries=3
    local retry_count=0
    
    local filter="{\"Dimensions\":{\"Key\":\"${dimension}\",\"Values\":[\"${value}\"]}}"
    
    while [ $retry_count -lt $max_retries ]; do
        rate_limit
        
        if aws ce get-cost-forecast \
            --time-period "${TIME_PERIOD}" \
            --metric "${metric}" \
            --granularity "${GRANULARITY}" \
            --prediction-interval-level 95 \
            --filter "${filter}" > "${output_file}" 2>/dev/null; then
            
            if [[ -f "${output_file}" ]]; then
                # Process the JSON and convert to CSV
                jq -r --arg dim "${dimension}" \
                   --arg val "${value}" \
                   --arg met "${metric}" \
                   '.ForecastResultsByTime[] | [
                       $dim,
                       $val,
                       $met,
                       .TimePeriod.Start,
                       .TimePeriod.End,
                       .MeanValue,
                       .PredictionIntervalLowerBound,
                       .PredictionIntervalUpperBound
                   ] | @csv' "${output_file}" >> "${OUTPUT_FILE}.tmp" 2>/dev/null
                
                rm "${output_file}"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            log "WARNING" "Retry ${retry_count}/${max_retries} for ${dimension}=${value}, metric=${metric}"
            sleep $((retry_count * 2))  # Exponential backoff
        fi
    done
    
    log "ERROR" "Failed to fetch forecast after ${max_retries} retries: ${dimension}=${value}, metric=${metric}"
    failed_jobs=$((failed_jobs + 1))
    return 1
}

# Enhanced parallel processing with better job control
process_forecast_parallel() {
    echo "Dimension,Value,Metric,StartDate,EndDate,MeanValue,LowerBound,UpperBound" > "${OUTPUT_FILE}"
    touch "${OUTPUT_FILE}.tmp"

    # Calculate total jobs and cache dimension values
    log "INFO" "Calculating total jobs and caching dimension values..."
    declare -A dimension_values
    total_jobs=0
    
    for dimension in "${SELECTED_DIMENSIONS[@]}"; do
        log "INFO" "Fetching values for dimension: ${dimension}"
        dimension_values[$dimension]=$(get_dimension_values "${dimension}")
        
        if [[ -n "${dimension_values[$dimension]}" ]]; then
            value_count=$(echo "${dimension_values[$dimension]}" | wc -l)
            dimension_total=$((value_count * ${#SELECTED_METRICS[@]}))
            total_jobs=$((total_jobs + dimension_total))
            
            log "INFO" "Found ${value_count} values for ${dimension}, adding ${dimension_total} jobs"
        else
            log "WARNING" "No values found for dimension: ${dimension}"
        fi
    done

    if [ $total_jobs -eq 0 ]; then
        log "ERROR" "No forecast jobs to process"
        exit 1
    fi

    log "INFO" "Total forecast jobs to process: ${total_jobs}"

    # Create a FIFO for job control
    mkfifo "${TEMP_DIR}/jobs.fifo"

    # Start background process to limit concurrent jobs
    exec 3<>"${TEMP_DIR}/jobs.fifo"
    for ((i=0; i<MAX_PARALLEL; i++)); do
        echo >&3
    done

    completed_jobs=0
    failed_jobs=0

    # Process each dimension
    for dimension in "${SELECTED_DIMENSIONS[@]}"; do
        if [[ -z "${dimension_values[$dimension]}" ]]; then
            continue
        fi
        
        log "INFO" "Processing dimension: ${dimension}"
        
        echo "${dimension_values[$dimension]}" | while read -r value; do
            # Skip empty values
            [ -z "$value" ] && continue
            
            for metric in "${SELECTED_METRICS[@]}"; do
                # Wait for a slot
                read -u3
                {
                    if fetch_forecast "${dimension}" "${value}" "${metric}"; then
                        log "DEBUG" "Successfully fetched: ${dimension}=${value}, metric=${metric}"
                    fi
                    echo >&3  # Release the slot
                    
                    # Update progress atomically
                    {
                        ((completed_jobs++))
                        progress=$((completed_jobs * 100 / total_jobs))
                        display_progress_bar $progress "Processing forecasts"
                    } 2>/dev/null
                } &
            done
        done
    done

    # Wait for all background jobs to complete
    wait

    # Clean up
    exec 3>&-
    rm "${TEMP_DIR}/jobs.fifo"

    # Combine results
    if [[ -f "${OUTPUT_FILE}.tmp" ]]; then
        cat "${OUTPUT_FILE}.tmp" >> "${OUTPUT_FILE}"
        rm "${OUTPUT_FILE}.tmp"
        echo  # New line after progress bar
        
        local record_count=$(wc -l < "${OUTPUT_FILE}")
        record_count=$((record_count - 1))  # Subtract header
        
        log "SUCCESS" "Data collection completed"
        log "INFO" "Total records collected: ${record_count}"
        
        if [ $failed_jobs -gt 0 ]; then
            log "WARNING" "Failed jobs: ${failed_jobs}"
        fi
    else
        log "ERROR" "No data was collected"
        exit 1
    fi
}

# Enhanced option selection with better UX
select_options() {
    display_section_header "METRIC SELECTION"
    echo -e "${CYAN}${BOLD}Available AWS Cost Explorer Metrics:${NC}"
    echo -e "${MAGENTA}0)${NC} All metrics (recommended for comprehensive analysis)"
    
    for i in "${!METRICS[@]}"; do
        local description=""
        case "${METRICS[$i]}" in
            "AMORTIZED_COST") description=" - Amortized cost including RIs/SPs";;
            "BLENDED_COST") description=" - Blended cost across accounts";;
            "UNBLENDED_COST") description=" - Actual cost without blending";;
            "USAGE_QUANTITY") description=" - Usage quantity metrics";;
        esac
        echo -e "${MAGENTA}$((i+1)))${NC} ${METRICS[$i]}${description}"
    done
    
    echo -e "\n${BOLD}Enter your choice (0 for all, or comma-separated numbers):${NC}"
    read -p "→ " choices
    
    SELECTED_METRICS=()
    if [[ "$choices" == "0" ]]; then
        SELECTED_METRICS=("${METRICS[@]}")
        log "INFO" "Selected all metrics (${#SELECTED_METRICS[@]} total)"
    else
        IFS=',' read -ra NUMS <<< "$choices"
        for num in "${NUMS[@]}"; do
            num=$(echo "$num" | xargs)  # Trim whitespace
            if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#METRICS[@]}" ]; then
                SELECTED_METRICS+=("${METRICS[$((num-1))]}")
            else
                log "WARNING" "Invalid metric selection: ${num}"
            fi
        done
        log "INFO" "Selected ${#SELECTED_METRICS[@]} metrics: ${SELECTED_METRICS[*]}"
    fi
    
    if [ ${#SELECTED_METRICS[@]} -eq 0 ]; then
        log "ERROR" "No valid metrics selected"
        exit 1
    fi
    
    display_section_header "DIMENSION SELECTION"
    echo -e "${CYAN}${BOLD}Available AWS Cost Explorer Dimensions:${NC}"
    echo -e "${MAGENTA}0)${NC} All dimensions (comprehensive but slower)"
    echo -e "${MAGENTA}99)${NC} Recommended dimensions (SERVICE, REGION, LINKED_ACCOUNT)"
    
    for i in "${!DIMENSIONS[@]}"; do
        local description=""
        case "${DIMENSIONS[$i]}" in
            "SERVICE") description=" - AWS Service breakdown";;
            "REGION") description=" - AWS Region breakdown";;
            "LINKED_ACCOUNT") description=" - Account breakdown";;
            "INSTANCE_TYPE") description=" - EC2 instance types";;
        esac
        echo -e "${MAGENTA}$((i+1)))${NC} ${DIMENSIONS[$i]}${description}"
    done
    
    echo -e "\n${BOLD}Enter your choice (0 for all, 99 for recommended, or comma-separated numbers):${NC}"
    read -p "→ " choices
    
    SELECTED_DIMENSIONS=()
    if [[ "$choices" == "0" ]]; then
        SELECTED_DIMENSIONS=("${DIMENSIONS[@]}")
        log "INFO" "Selected all dimensions (${#SELECTED_DIMENSIONS[@]} total)"
    elif [[ "$choices" == "99" ]]; then
        SELECTED_DIMENSIONS=("SERVICE" "REGION" "LINKED_ACCOUNT")
        log "INFO" "Selected recommended dimensions: ${SELECTED_DIMENSIONS[*]}"
    else
        IFS=',' read -ra NUMS <<< "$choices"
        for num in "${NUMS[@]}"; do
            num=$(echo "$num" | xargs)  # Trim whitespace
            if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#DIMENSIONS[@]}" ]; then
                SELECTED_DIMENSIONS+=("${DIMENSIONS[$((num-1))]}")
            else
                log "WARNING" "Invalid dimension selection: ${num}"
            fi
        done
        log "INFO" "Selected ${#SELECTED_DIMENSIONS[@]} dimensions: ${SELECTED_DIMENSIONS[*]}"
    fi
    
    if [ ${#SELECTED_DIMENSIONS[@]} -eq 0 ]; then
        log "ERROR" "No valid dimensions selected"
        exit 1
    fi
    
    display_section_header "GRANULARITY SELECTION"
    echo -e "${CYAN}${BOLD}Select Forecast Granularity:${NC}"
    echo -e "${MAGENTA}1)${NC} DAILY (detailed day-by-day forecast)"
    echo -e "${MAGENTA}2)${NC} MONTHLY (monthly aggregated forecast)"
    
    echo -e "\n${BOLD}Enter your choice [1-2]:${NC}"
    read -p "→ " choice
    
    case $choice in
        1) 
            GRANULARITY="DAILY"
            log "INFO" "Selected DAILY granularity"
            ;;
        2) 
            GRANULARITY="MONTHLY"
            log "INFO" "Selected MONTHLY granularity"
            ;;
        *) 
            log "ERROR" "Invalid granularity choice"
            exit 1
            ;;
    esac
}

# Enhanced S3 upload with validation
upload_to_s3() {
    display_section_header "S3 UPLOAD CONFIGURATION"
    echo -e "\n${BOLD}Enter S3 bucket name for data storage (or press Enter to skip):${NC}"
    echo -e "${CYAN}Note: Bucket must exist and you must have write permissions${NC}"
    read -p "→ " S3_BUCKET
    
    if [[ -n "${S3_BUCKET}" ]]; then
        # Validate bucket exists and is accessible
        local spinner_text="Validating S3 bucket access..."
        display_spinner "${spinner_text}"
        
        if ! aws s3 ls "s3://${S3_BUCKET}" >/dev/null 2>&1; then
            echo
            log "ERROR" "Cannot access S3 bucket: ${S3_BUCKET}"
            log "INFO" "Please ensure the bucket exists and you have proper permissions"
            exit 1
        fi
        
        echo
        log "SUCCESS" "S3 bucket access validated"
        
        local s3_key="forecasts/$(basename ${OUTPUT_FILE})"
        spinner_text="Uploading forecast data to S3..."
        display_spinner "${spinner_text}"
        
        if aws s3 cp "${OUTPUT_FILE}" "s3://${S3_BUCKET}/${s3_key}" >/dev/null 2>&1; then
            echo
            log "SUCCESS" "File uploaded to s3://${S3_BUCKET}/${s3_key}"
            
            # Upload log file as well
            local log_key="forecasts/logs/$(basename ${LOG_FILE})"
            aws s3 cp "${LOG_FILE}" "s3://${S3_BUCKET}/${log_key}" >/dev/null 2>&1
            log "INFO" "Log file uploaded to s3://${S3_BUCKET}/${log_key}"
        else
            echo
            log "ERROR" "Failed to upload to S3"
            exit 1
        fi
    else
        log "INFO" "Skipping S3 upload"
    fi
}

# Enhanced QuickSight manifest generation
generate_quicksight_manifest() {
    if [[ -z "${S3_BUCKET}" ]]; then
        log "INFO" "Skipping QuickSight manifest (no S3 bucket specified)"
        return 0
    fi
    
    display_section_header "QUICKSIGHT MANIFEST GENERATION"
    
    local csv_s3_uri="s3://${S3_BUCKET}/forecasts/$(basename ${OUTPUT_FILE})"
    local manifest_file="${OUTPUT_DIR}/quicksight-manifest.json"
    
    log "INFO" "Generating QuickSight manifest file..."
    
    cat > "${manifest_file}" << EOF
{
    "fileLocations": [
        {
            "URIs": [
                "${csv_s3_uri}"
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

    local manifest_s3_key="forecasts/quicksight-manifest.json"
    if aws s3 cp "${manifest_file}" "s3://${S3_BUCKET}/${manifest_s3_key}" >/dev/null 2>&1; then
        log "SUCCESS" "QuickSight manifest uploaded to s3://${S3_BUCKET}/${manifest_s3_key}"
        
        display_section_header "QUICKSIGHT SETUP INSTRUCTIONS"
        echo -e "${GREEN}${BOLD}🎯 QuickSight Dashboard Setup:${NC}"
        echo -e "${CYAN}1.${NC} Open AWS QuickSight in your browser"
        echo -e "${CYAN}2.${NC} Click 'New analysis' → 'New dataset'"
        echo -e "${CYAN}3.${NC} Choose 'S3' as data source"
        echo -e "${CYAN}4.${NC} Enter manifest URL: ${BOLD}s3://${S3_BUCKET}/${manifest_s3_key}${NC}"
        echo -e "${CYAN}5.${NC} Configure QuickSight permissions to access your S3 bucket"
        echo -e "${CYAN}6.${NC} Create visualizations using the imported data"
        echo
        echo -e "${YELLOW}${BOLD}💡 Pro Tips:${NC}"
        echo -e "• Use 'MeanValue' for primary cost metrics"
        echo -e "• Create time-series charts with StartDate on X-axis"
        echo -e "• Use 'Dimension' and 'Value' for filtering and grouping"
        echo -e "• Set up automated refresh for daily updates"
    else
        log "ERROR" "Failed to upload QuickSight manifest"
    fi
}

# Enhanced cleanup with better error handling
cleanup() {
    log "INFO" "Cleaning up temporary files..."
    if [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
        log "DEBUG" "Temporary directory cleaned up"
    fi
}

# Display usage information
show_usage() {
    echo -e "${BOLD}AWS Cost Forecast Toolkit v${SCRIPT_VERSION}${NC}"
    echo
    echo -e "${BOLD}USAGE:${NC}"
    echo "  $0 [OPTIONS]"
    echo
    echo -e "${BOLD}OPTIONS:${NC}"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  --start-date DATE       Set custom start date (YYYY-MM-DD)"
    echo "  --end-date DATE         Set custom end date (YYYY-MM-DD)"
    echo "  --bucket BUCKET         Set S3 bucket for output"
    echo "  --region REGION         Set AWS region"
    echo "  --dry-run               Validate configuration without running"
    echo
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "  $0                                    # Interactive mode"
    echo "  $0 --bucket my-forecasts --region us-east-1"
    echo "  $0 --start-date 2024-01-01 --end-date 2024-12-31"
    echo
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "AWS Cost Forecast Toolkit v${SCRIPT_VERSION}"
                exit 0
                ;;
            --start-date)
                START_DATE="$2"
                shift 2
                ;;
            --end-date)
                END_DATE="$2"
                shift 2
                ;;
            --bucket)
                S3_BUCKET="$2"
                shift 2
                ;;
            --region)
                AWS_DEFAULT_REGION="$2"
                export AWS_DEFAULT_REGION
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
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
    # Parse command line arguments
    parse_arguments "$@"
    
    clear
    display_banner "AWS Cost Forecast Toolkit v${SCRIPT_VERSION}"
    
    log "INFO" "Starting AWS Cost Forecast Toolkit"
    log "INFO" "Version: ${SCRIPT_VERSION}"
    log "INFO" "Output directory: ${OUTPUT_DIR}"
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Check prerequisites
    check_prerequisites
    
    # Get time period (unless provided via CLI)
    if [[ -z "${START_DATE}" || -z "${END_DATE}" ]]; then
        get_time_period
    else
        TIME_PERIOD="Start=${START_DATE},End=${END_DATE}"
        log "INFO" "Using provided time period: ${START_DATE} to ${END_DATE}"
    fi
    
    # Select options
    select_options
    
    # Exit if dry run
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "Dry run completed successfully"
        log "INFO" "Configuration validated - ready for actual run"
        exit 0
    fi
    
    # Process forecasts
    display_section_header "FORECAST PROCESSING"
    log "INFO" "Starting parallel forecast generation..."
    process_forecast_parallel
    
    # Display results
    if [[ -f "${OUTPUT_FILE}" ]]; then
        local records=$(wc -l < "${OUTPUT_FILE}")
        display_section_header "RESULTS SUMMARY"
        log "SUCCESS" "Generated forecast with $((records-1)) records"
        log "INFO" "Output file: ${OUTPUT_FILE}"
        log "INFO" "Log file: ${LOG_FILE}"
        
        # Upload to S3
        upload_to_s3
        
        # Generate QuickSight manifest
        generate_quicksight_manifest
        
        # Final summary
        display_section_header "COMPLETION SUMMARY"
        echo -e "${GREEN}${BOLD}✅ AWS Cost Forecast Generation Complete!${NC}"
        echo
        echo -e "${CYAN}📊 Data Summary:${NC}"
        echo -e "  • Records generated: $((records-1))"
        echo -e "  • Metrics analyzed: ${#SELECTED_METRICS[@]}"
        echo -e "  • Dimensions processed: ${#SELECTED_DIMENSIONS[@]}"
        echo -e "  • Time period: ${START_DATE} to ${END_DATE}"
        echo
        echo -e "${CYAN}📁 Output Files:${NC}"
        echo -e "  • CSV Data: ${OUTPUT_FILE}"
        echo -e "  • Log File: ${LOG_FILE}"
        
        if [[ -n "${S3_BUCKET}" ]]; then
            echo -e "  • S3 Location: s3://${S3_BUCKET}/forecasts/"
            echo -e "  • QuickSight Manifest: s3://${S3_BUCKET}/forecasts/quicksight-manifest.json"
        fi
        
        echo
        echo -e "${YELLOW}${BOLD}🚀 Next Steps:${NC}"
        echo -e "1. Review the generated CSV file for forecast data"
        echo -e "2. Import data into QuickSight for visualization"
        echo -e "3. Set up automated scheduling for regular updates"
        echo -e "4. Share insights with your team"
        
        if [ $failed_jobs -gt 0 ]; then
            echo
            echo -e "${YELLOW}⚠️  Note: ${failed_jobs} forecast requests failed. Check the log file for details.${NC}"
        fi
        
    else
        log "ERROR" "No forecast data generated"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
