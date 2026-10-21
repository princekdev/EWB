# Evidence, Viva & Final Checklist
Everything here is **YOU MUST RUN THIS**; all screenshots must be genuine (show Region/URL bar and, in terminals, the prompt + `date`). Nothing has been created in AWS yet.

## Cost warning (before you start)
Chargeable: 3× EC2 (t3.micro; free only if your account's free tier covers it), root EBS volumes, bastion public IPv4 (~$0.005/hr). NOT created: NAT Gateway, Elastic IP. Use the instructor-approved type: `INSTANCE_TYPE=t3.micro ./scripts/01-build-base.sh`. Don't leave it running.

## Run order
1. **YOU MUST RUN:** `chmod +x scripts/*.sh && ./scripts/01-build-base.sh` → expect IDs printed, `ids.env` + `commands/ssh-config.txt` created. Screenshot: NO.
2. **YOU MUST RUN:** `cat commands/ssh-config.txt >> ~/.ssh/config` (WSL: use WSL's ~/.ssh; if you used CloudShell, download `~/.ssh/ewb-lab.pem` to your laptop, `chmod 400`). Never commit it.
3. Console screenshots 01–07 (peering one later) + **Test 1** (`ssh ewb-app-a`, `ping -c 4 10.20.1.10`) → 100% loss → screenshot 08.
4. **YOU MUST RUN:** `./scripts/02-peering-routes.sh` → expect `active`. Screenshots 07, 04a-c. Then Tests 2–6 (`commands/validation-commands.txt`).
5. Save all screenshots, then **YOU MUST RUN:** `./scripts/99-cleanup.sh` (order: terminate EC2 → key pair → peering → routes → SGs → associations → subnets → RTs → IGW → VPCs → verify). Screenshot 14 = empty verify output + console.

## Screenshots (folder `screenshots/`; section = where in the repo/report)
| File | Open | Must be visible | Section |
|---|---|---|---|
| 01-vpc-a.png | VPC → ewb-vpc-a | name, ID, 10.10.0.0/16, available, region | README VPC A |
| 02-vpc-b.png | VPC → ewb-vpc-b | name, ID, 10.20.0.0/16 | README VPC B |
| 03-subnets.png | Subnets | 3 subnets, CIDRs, VPC, auto-assign public IP | network-design |
| 03b-igw.png | Internet gateways | ewb-igw-a attached to ewb-vpc-a (only IGW) | network-design |
| 04a/b/c-rt-*.png | each RT → Routes AND Subnet associations (after peering) | routes incl. pcx; no 0.0.0.0/0 on private RTs | routing |
| 05a/b/c-sg-*.png | each SG → Inbound rules | exact /32 sources, no 0.0.0.0/0 | security |
| 06-ec2-instances.png | EC2 list + columns Private IPv4, Public IPv4, Subnet, SG | 3 running; app-a/b public blank | README EC2 |
| 06b-no-public-ip.png | CLI describe-instances table | name/private IP/None | testing |
| 07-vpc-peering-active.png | Peering connections | ewb-a-b-peer, pcx-ID, Active, requester A, accepter B | README peering |
| 08-baseline-ping-failed.png | app-a terminal, before 02 | prompt, command, 100% loss | testing |
| 09-forward-ping-success.png | app-a | command, 4 replies, 0% loss | testing |
| 10-reverse-ping-success.png | app-b: `ping -c 4 10.10.2.10` | prompt, 0% loss | testing |
| 11-app-b-ssh.png | laptop `ssh ewb-app-b` | command, banner, app-b prompt, `hostname -I`=10.20.1.10 | testing |
| 11b-metadata-no-public.png | app-a and app-b | HTTP 404 public-ipv4, private IP, ip addr | testing |
| 12-controlled-failure.png | SG app-b inbound without ICMP rule (SSH rule visible) + app-a ping loss | both in one image or 12a/12b | testing |
| 13-recovery.png | SG restored + ping 0% loss | rule 10.10.2.10/32 ICMP back | testing |
| 14-cleanup.png | verify output + console empty lists | no instances/volumes/VPCs/peering/EIP | README cleanup |
Diagram: open `architecture/architecture-diagram.svg` in a browser, save/screenshot as `architecture/architecture-diagram.png`.

## Viva answers
1. Return route: replies need a path back; B needs 10.10.0.0/16→pcx or responses are dropped.
2. Traffic comes from the bastion over the peering, so its source is 10.10.1.10 (private), not your laptop.
3. Active only means the link exists; routes, SGs and NACLs must also allow traffic.
4. No; peering doesn't allow edge-to-edge use of A's IGW.
5. Overlapping CIDRs make routing ambiguous; AWS blocks peering/routes.
6. Bastion is the sole internet-facing entry; apps stay unreachable from the internet.
7. /32 = one exact host (least privilege).
8. The bastion is in the public subnet; it needs 10.20.0.0/16→pcx to reach App-B (ProxyJump).
9. No, peering is non-transitive.
10. B needs no internet; everything is private via peering, so no IGW = smaller attack surface.

## Final report (`report/YourName_EWB_VPC_Peering.pdf`)
Word/Docs → PDF in this order: cover → diagram → inventory (ids.env + console: VPC/subnet/RT/instance/SG/pcx IDs, private IPs, bastion public IP) → network design → routing (3 RTs, associations, forward/return) → security (rules, /32, bastion) → testing (08–13) → troubleshooting (real issues) → cleanup (14) → learning summary. Paste me your `ids.env` and results and I'll draft the text.

## FINAL CHECKLIST
| Requirement | Auto (script/file) | You run | Screenshot |
|---|---|---|---|
| VPCs, subnets, IGW, RTs, SGs, key, 3 EC2 | ✔ 01 | run script | 01–06 |
| Peering, accept, 3 routes | ✔ 02 | run script | 04, 07 |
| SSH ProxyJump config | ✔ generated | append to ~/.ssh/config | – |
| Tests 1–6 | – | ✔ | 08–13, 06b, 11b |
| Architecture diagram | ✔ SVG | export PNG | – |
| README/docs/commands | ✔ | fill real outputs/pcx-ID | – |
| Report PDF | outline | ✔ | – |
| Cleanup | ✔ 99 | ✔ | 14 |
| GitHub push | ✔ .gitignore blocks pem/ids.env | ✔ git init/push | – |
