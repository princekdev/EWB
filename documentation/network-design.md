# Network Design
| Resource | Name | CIDR/IP |
|---|---|---|
| VPC A | ewb-vpc-a | 10.10.0.0/16 |
| Subnet | ewb-a-public | 10.10.1.0/24 |
| Subnet | ewb-a-private | 10.10.2.0/24 |
| VPC B | ewb-vpc-b | 10.20.0.0/16 |
| Subnet | ewb-b-private | 10.20.1.0/24 |
| Bastion / App-A / App-B | | 10.10.1.10 / 10.10.2.10 / 10.20.1.10 |

10.10.0.0/16 and 10.20.0.0/16 do not overlap, so peering routes are unambiguous. No NAT Gateway; IGW only in VPC A.
