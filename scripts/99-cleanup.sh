#!/usr/bin/env bash
# ONLY after ALL screenshots are saved. Needs ids.env.
set -uo pipefail; source ids.env; export AWS_DEFAULT_REGION=$REGION
read -p "Screenshots saved? type YES: " a; [ "$a" = YES ] || exit 1
aws ec2 terminate-instances --instance-ids $BASTION $APPA $APPB >/dev/null
aws ec2 wait instance-terminated --instance-ids $BASTION $APPA $APPB
aws ec2 delete-key-pair --key-name ewb-lab; rm -f ~/.ssh/ewb-lab.pem   # optional
[ -n "${PCX:-}" ] && aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PCX
aws ec2 delete-route --route-table-id $RTAPRIV --destination-cidr-block 10.20.0.0/16
aws ec2 delete-route --route-table-id $RTBPRIV --destination-cidr-block 10.10.0.0/16
aws ec2 delete-route --route-table-id $RTAPUB  --destination-cidr-block 10.20.0.0/16
for G in $SGBAS $SGA $SGB; do aws ec2 delete-security-group --group-id $G; done
for RT in $RTAPUB $RTAPRIV $RTBPRIV; do
  for A in $(aws ec2 describe-route-tables --route-table-ids $RT --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' --output text); do aws ec2 disassociate-route-table --association-id $A; done
done
for S in $SNAPUB $SNAPRIV $SNBPRIV; do aws ec2 delete-subnet --subnet-id $S; done
for RT in $RTAPUB $RTAPRIV $RTBPRIV; do aws ec2 delete-route-table --route-table-id $RT; done
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPCA; aws ec2 delete-internet-gateway --internet-gateway-id $IGW
aws ec2 delete-vpc --vpc-id $VPCA; aws ec2 delete-vpc --vpc-id $VPCB
echo "--- VERIFY (all should be empty) ---"
aws ec2 describe-vpcs --filters Name=tag:Project,Values=EWB-VPC-Peering --query 'Vpcs[].VpcId'
aws ec2 describe-instances --filters Name=tag:Project,Values=EWB-VPC-Peering Name=instance-state-name,Values=pending,running,stopped,stopping --query 'Reservations[].Instances[].InstanceId'
aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[].VolumeId'
aws ec2 describe-addresses --query 'Addresses[].PublicIp'
aws ec2 describe-vpc-peering-connections --filters Name=status-code,Values=active,pending-acceptance --query 'VpcPeeringConnections[].VpcPeeringConnectionId'
