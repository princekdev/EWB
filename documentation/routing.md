# Routing
| Route table | Destination | Target |
|---|---|---|
| ewb-rt-a-public | 10.10.0.0/16 | local |
| | 0.0.0.0/0 | ewb-igw-a |
| | 10.20.0.0/16 | pcx-ID |
| ewb-rt-a-private | 10.10.0.0/16 | local |
| | 10.20.0.0/16 | pcx-ID |
| ewb-rt-b-private | 10.20.0.0/16 | local |
| | 10.10.0.0/16 | pcx-ID |

Forward: App-A → rt-a-private → pcx → App-B. Return: App-B → rt-b-private → pcx → App-A. Peering is non-transitive.
