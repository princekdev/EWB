#!/usr/bin/env bash
# Builds everything EXCEPT peering + peer routes (needed for Test 1 baseline). Run from repo root in WSL/Linux/CloudShell, aws cli v2 configured.
set -euo pipefail
export AWS_DEFAULT_REGION=${AWS_REGION:-$(aws configure get region)}
OUT=ids.env; : > $OUT
save(){ echo "$1=$2" >> $OUT; echo "$1=$2"; }
T(){ echo "ResourceType=$1,Tags=[{Key=Name,Value=$2},{Key=Project,Value=EWB-VPC-Peering}]"; }
MYIP=$(curl -s https://checkip.amazonaws.com | tr -d '\n'); echo "My IP: $MYIP"
AZ=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
save REGION "$AWS_DEFAULT_REGION"; save AZ $AZ
VPCA=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 --tag-specifications "$(T vpc ewb-vpc-a)" --query Vpc.VpcId --output text); save VPCA $VPCA
VPCB=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications "$(T vpc ewb-vpc-b)" --query Vpc.VpcId --output text); save VPCB $VPCB
sn(){ aws ec2 create-subnet --vpc-id $1 --cidr-block $2 --availability-zone $AZ --tag-specifications "$(T subnet $3)" --query Subnet.SubnetId --output text; }
SNAPUB=$(sn $VPCA 10.10.1.0/24 ewb-a-public); save SNAPUB $SNAPUB
SNAPRIV=$(sn $VPCA 10.10.2.0/24 ewb-a-private); save SNAPRIV $SNAPRIV
SNBPRIV=$(sn $VPCB 10.20.1.0/24 ewb-b-private); save SNBPRIV $SNBPRIV
aws ec2 modify-subnet-attribute --subnet-id $SNAPUB --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SNAPRIV --no-map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SNBPRIV --no-map-public-ip-on-launch
IGW=$(aws ec2 create-internet-gateway --tag-specifications "$(T internet-gateway ewb-igw-a)" --query InternetGateway.InternetGatewayId --output text); save IGW $IGW
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPCA
rt(){ aws ec2 create-route-table --vpc-id $1 --tag-specifications "$(T route-table $2)" --query RouteTable.RouteTableId --output text; }
RTAPUB=$(rt $VPCA ewb-rt-a-public); save RTAPUB $RTAPUB
RTAPRIV=$(rt $VPCA ewb-rt-a-private); save RTAPRIV $RTAPRIV
RTBPRIV=$(rt $VPCB ewb-rt-b-private); save RTBPRIV $RTBPRIV
aws ec2 create-route --route-table-id $RTAPUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW >/dev/null
aws ec2 associate-route-table --route-table-id $RTAPUB --subnet-id $SNAPUB >/dev/null
aws ec2 associate-route-table --route-table-id $RTAPRIV --subnet-id $SNAPRIV >/dev/null
aws ec2 associate-route-table --route-table-id $RTBPRIV --subnet-id $SNBPRIV >/dev/null
sg(){ aws ec2 create-security-group --group-name $2 --description "$3" --vpc-id $1 --tag-specifications "$(T security-group $2)" --query GroupId --output text; }
SGBAS=$(sg $VPCA ewb-sg-bastion "EWB bastion SSH from my IP"); save SGBAS $SGBAS
SGA=$(sg $VPCA ewb-sg-app-a "EWB app A"); save SGA $SGA
SGB=$(sg $VPCB ewb-sg-app-b "EWB app B"); save SGB $SGB
ssh_rule(){ echo "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$1,Description=ssh}]"; }
icmp_rule(){ echo "IpProtocol=icmp,FromPort=8,ToPort=-1,IpRanges=[{CidrIp=$1,Description=icmp-echo-request}]"; }
aws ec2 authorize-security-group-ingress --group-id $SGBAS --ip-permissions "$(ssh_rule $MYIP/32)" >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SGA --ip-permissions "$(ssh_rule 10.10.1.10/32)" "$(icmp_rule 10.20.1.10/32)" >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SGB --ip-permissions "$(ssh_rule 10.10.1.10/32)" "$(icmp_rule 10.10.2.10/32)" >/dev/null
mkdir -p ~/.ssh
aws ec2 create-key-pair --key-name ewb-lab --query KeyMaterial --output text > ~/.ssh/ewb-lab.pem   # private key stays local
chmod 400 ~/.ssh/ewb-lab.pem
AMI=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text); save AMI $AMI
IT=${INSTANCE_TYPE:-t3.micro}
run(){ aws ec2 run-instances --image-id $AMI --instance-type $IT --key-name ewb-lab --subnet-id $1 --private-ip-address $2 --security-group-ids $3 --metadata-options HttpTokens=required --tag-specifications "$(T instance $4)" --query 'Instances[0].InstanceId' --output text; }
BASTION=$(run $SNAPUB 10.10.1.10 $SGBAS ewb-bastion); save BASTION $BASTION
APPA=$(run $SNAPRIV 10.10.2.10 $SGA ewb-app-a); save APPA $APPA
APPB=$(run $SNBPRIV 10.20.1.10 $SGB ewb-app-b); save APPB $APPB
aws ec2 wait instance-running --instance-ids $BASTION $APPA $APPB
BIP=$(aws ec2 describe-instances --instance-ids $BASTION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text); save BASTION_IP $BIP
cat > commands/ssh-config.txt <<EOT
Host ewb-bastion
    HostName $BIP
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes

Host ewb-app-a
    HostName 10.10.2.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion

Host ewb-app-b
    HostName 10.20.1.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion
EOT
echo "DONE. Append commands/ssh-config.txt to ~/.ssh/config, run TEST 1 BEFORE scripts/02-peering-routes.sh"
