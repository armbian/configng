``` mermaid
graph LR
  A{Select interface} --> B[Configure];
  A{Select interface} --> C[Drop];
  C ---->A;
  B -->F[DHCP];
  B ---->G[Static];
  G ------>| MAC, IP, route, GW, DNS|H[Configured];
  F -->| MAC | H[Configured];
```
