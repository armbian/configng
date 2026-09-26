Armbian's defaults are tuned for the machine most Armbian users have: a single-board computer booting from a memory card, where flash write endurance is the scarce resource and RAM is measured in hundreds of megabytes. Writeback is deferred for two minutes so that many small writes coalesce into few erase blocks, and swapping into compressed RAM is preferred over any real swap device. For that machine those defaults are correct.

The same userspace also runs on many-core NVMe build servers, NAS boxes and desktops. There the same settings are not merely suboptimal: when a machine has tens of gigabytes of page cache, two minutes of deferred writeback is a large backlog, and anything which asks for the data to be on disk has to clear all of it first — while every process waiting on that flush sits blocked and uninterruptible, and the CPU does nothing.

A tuning profile tells the system which of those machines it actually is.

*What a profile controls*

- **Swap pressure** — how eagerly the kernel moves anonymous pages out of RAM
- **Dirty limits** — how much unwritten data may accumulate before writers are throttled
- **Writeback intervals** — how often the flusher threads run, and how old a page must be before they take it
- **Journal commit interval** — how long ext4 batches metadata before committing it to disk
- **CPU energy bias** — where on the power/performance curve the processor is asked to sit

---

Switching profile takes effect immediately and survives reboot. Nothing needs restarting, no service is interrupted, and `reset` returns the machine to distribution defaults.
