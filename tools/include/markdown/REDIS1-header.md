Redis is an open-source, in-memory data structure store, used as a database, cache, and message broker.  
This module deploys it as an **in-memory LRU cache with RDB persistence** — an RDB snapshot is written on graceful shutdown and reloaded on start, so planned restarts keep the data.

**Key Features:**
- Extremely fast performance with in-memory storage
- RDB snapshot on shutdown (AOF disabled) — survives planned restarts with minimal runtime I/O
- Bounded memory with `allkeys-lru` eviction (default `maxmemory` 64 GB)
- Throughput-tuned for high concurrency: threaded network I/O, background (lazyfree) eviction, active defragmentation
- Raised open-files limit for many concurrent connections
- Simple API and wide client support

Ideal as a caching layer or shared remote cache (for example, a ccache/build cache backend) where data should survive restarts but a hard crash losing the last snapshot is acceptable.
