#!/bin/bash

# Define paths and parameters
SOURCE_FILE="create-ec2.sh"
AWS_REGION="us-east-1"

# Ensure the source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file $SOURCE_FILE does not exist."
    exit 1
fi

# Read instance IDs and store in an array
INSTANCE_IDS=()
while IFS= read -r line; do
    if [[ $line =~ ^i- ]]; then
        INSTANCE_IDS+=("$line")
    fi
done < "$SOURCE_FILE"

# Read Route 53 Hosted Zone ID and Record Sets
HOSTED_ZONE_ID=""
RECORD_SETS=()
while IFS= read -r line; do
    if [[ $line =~ ^Z ]]; then
        HOSTED_ZONE_ID="$line"
    elif [[ $line =~ \. ]]; then
        RECORD_SETS+=("$line")
    fi
done < "$SOURCE_FILE"

# Set AWS region
aws configure set region "$AWS_REGION"

# Terminate EC2 instances
if [ ${#INSTANCE_IDS[@]} -gt 0 ]; then
    echo "Terminating AWS instances..."
    aws ec2 terminate-instances --instance-ids "${INSTANCE_IDS[@]}"
    echo "AWS instances termination initiated."
else
    echo "No EC2 instance IDs found."
fi

# Delete Route 53 records
if [ -n "$HOSTED_ZONE_ID" ] && [ ${#RECORD_SETS[@]} -gt 0 ]; then
    echo "Deleting records from Route 53 hosted zone $HOSTED_ZONE_ID..."
    
    # Create a JSON file for the change batch
    CHANGE_BATCH_FILE=$(mktemp)
    echo '{"Changes": [' > "$CHANGE_BATCH_FILE"
    
    for record in "${RECORD_SETS[@]}"; do
        IFS=',' read -r NAME TYPE VALUE <<< "$record"
        echo "{\"Action\": \"DELETE\", \"ResourceRecordSet\": {\"Name\": \"$NAME\", \"Type\": \"$TYPE\", \"TTL\": 1, \"ResourceRecords\": [{\"Value\": \"$VALUE\"}]}}" >> "$CHANGE_BATCH_FILE"
        echo ',' >> "$CHANGE_BATCH_FILE"
    done
    
    # Remove trailing comma and close JSON array
    sed -i '$ s/,$//' "$CHANGE_BATCH_FILE"
    echo ']}' >> "$CHANGE_BATCH_FILE"
    
    # Apply the change batch to Route 53
    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch file://"$CHANGE_BATCH_FILE"
    
    echo "Route 53 records deletion initiated."
    
    # Clean up
    rm "$CHANGE_BATCH_FILE"
else
    echo "No Route 53 records or hosted zone ID found."
fi