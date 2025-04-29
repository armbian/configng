``` mermaid
graph LR
  A[Network] --> B[Add / Change interface];
  A[Network] --> O[Revert to defaults];
  A[Network] --> P[Show configuration];
  B ---->E[Wired];
  B ---->F[Wireless];
  E -->R[DHCP];
  E -->T[Static];
  E -->S[Spoof MAC];
  F -->X[Station];
  F -->W[Access point]; 
```
