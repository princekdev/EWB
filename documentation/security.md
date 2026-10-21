# Security
| SG | Rule | Source |
|---|---|---|
| ewb-sg-bastion | SSH 22 | my public IPv4 /32 |
| ewb-sg-app-a | SSH 22 | 10.10.1.10/32 |
| | ICMP echo request | 10.20.1.10/32 |
| ewb-sg-app-b | SSH 22 | 10.10.1.10/32 |
| | ICMP echo request | 10.10.2.10/32 |

Outbound default allow-all; NACLs default; nothing open to 0.0.0.0/0; private key stays on laptop only.
