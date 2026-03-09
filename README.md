# Eviction Vault - Simple README

## Overview

This repo refactors the original EvictionVault contract into a safer, modular setup. The old single file has been split into three small contracts and several security problems were fixed.

## What Was Wrong and How i Fixed It

- **Merkle root open to anyone** – now only owners can set the root.
- **Emergency withdraw open to anyone** – only owners can call it.
- **Pause/unpause not protected** – added owner-only modifiers.
- **`receive()` used `tx.origin`** – changed to `msg.sender`.
- **`withdraw`/`claim` used `.transfer()`** – replaced with low-level `call` and check success.
- **Timelock lacked enforcement** – full multi-sig + 1‑hour delay added.

Each fix is in `src/EvictionVault.sol` and enforced by `VaultModifiers.sol`.

## File Layout

```
src/
├── VaultStorage.sol       // state and data
├── VaultModifiers.sol     // onlyOwner / notPaused
└── EvictionVault.sol      // main logic

test/
└── EvictionVault.t.sol    // basic positive tests
```

