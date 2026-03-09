<!-- # Eviction Vault - Simple README

## Overview

This repo refactors the original EvictionVault contract into a safer, modular setup. The old single file has been split into three small contracts and several security problems were fixed.

## What Was Wrong and How We Fixed It

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

## How to Build & Test

```bash
# from workspace root
forge build    # should succeed
forge test -v  # runs 8 simple tests
```

The tests cover deposits, withdrawals, pause logic, owner-only functions, merkle root setting, receive behaviour, and the multi-sig timelock flow.

## Results

- Contract compiles cleanly.
- 8/8 tests pass.
- All listed vulnerabilities are patched.

## Notes

- This is Phase 1; further work could include formal verification, event indexing, upgradeability, and governance support.

## License

MIT

Last updated: March 9 2026

$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
``` -->
