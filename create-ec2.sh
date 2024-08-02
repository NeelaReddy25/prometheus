#!/bin/bash

instances=("prometheus" "node-1" "node-2" "elk" "frontend")
domain_name="neelareddy.store"
hosted_zone_id="Z001712433NLPH2AI8HH5"

for name in ${instances[@]}; do
    if [ $name == "prometheus" ] || [ $name == "elk" ]
    then
        instance_type="t3.medium"
    else
        instance_type="t3.micro"
    fi
    echo "Creating instance for: $name with instance type: $instance_type"
    instance_id=$(aws ec2 run-instances --image-id ami-041e2ea9402c46c32 --instance-type $instance_type --security-group-ids sg-0cd5626364cf1e071 --subnet-id subnet-045b66b79d1f5cc3f --query 'Instances[0].InstanceId' --output text)
    echo "Instance created for: $name"

    aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$name

    if [ $name == "node-1" ] || [ $name == "node-2" ]
    then
        aws ec2 create-tags --resources $instance_id --tags Key=Monitoring,Value=true
    fi

    if [ $name == "prometheus" ] || [ $name == "grafana" ] || [ $name == "frontend" ] || [ $name == "alertmanager" ]
    then
        aws ec2 wait instance-running --instance-ids $instance_id
        public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
        ip_to_use=$public_ip
    else
        private_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
        ip_to_use=$private_ip
    fi

    echo "Creating R53 record for: $name"
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '
    {
        "Comment": "Creating a record set for '$name'"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$name.$domain_name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$ip_to_use'"
            }]
        }
        }]
    }'
done