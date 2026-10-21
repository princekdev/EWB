#!/usr/bin/env bash
# Run ONLY after Test 1 baseline screenshot is captured.
set -euo pipefail; source ids.env; export AWS_DEFAULT_REGION=$REGION
PCX=$(aws ec2 create-vpc-peering-connection --vpc-id $VPCA --peer-vpc-id $VPCB --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=ewb-a-b-peer},{Key=Project,Value=EWB-VPC-Peering}]" --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
echo "PCX=$PCX" >> ids.env; echo "PCX=$PCX"
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PCX >/dev/null
aws ec2 wait vpc-peering-connection-exists --vpc-peering-connection-ids $PCX
aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $PCX --query 'VpcPeeringConnections[0].Status.Code' --output text   # must print: active
aws ec2 create-route --route-table-id $RTAPRIV --destination-cidr-block 10.20.0.0/16 --vpc-peering-connection-id $PCX >/dev/null
aws ec2 create-route --route-table-id $RTBPRIV --destination-cidr-block 10.10.0.0/16 --vpc-peering-connection-id $PCX >/dev/null
aws ec2 create-route --route-table-id $RTAPUB  --destination-cidr-block 10.20.0.0/16 --vpc-peering-connection-id $PCX >/dev/null
echo "Peering active + 3 routes added. Run Tests 2-6."
