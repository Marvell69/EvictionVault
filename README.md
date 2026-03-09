# Eviction Vault 

## Explanation

This repo refactors the original EvictionVault contract into a safer, modular setup. The old single file has been split into three small contracts and several security problems were fixed.

## What Was Wrong and How i Fixed It

- **Merkle root open to anyone** – now only owners can set the Merkle root.
- **Emergency withdraw open to anyone** – only the owners can call it.
- **Pause/unpause not protected** – added the owner-only modifiers.
- **`receive()` used `tx.origin`** – changed to them  `msg.sender`.
- **`withdraw`/`claim` used `.transfer()`** – replaced with low-level `call` and check success.
- **Timelock lacked enforcement** – full multi-sig + 1‑hour delay added.

Each fix is in `src/EvictionVault.sol` and enforced by `VaultModifiers.sol`.

## File Layout

```
src/
VaultStorage.sol       // state and data
VaultModifiers.sol     // onlyOwner / notPaused
EvictionVault.sol      // main contract

test/
EvictionVault.t.sol    // run basic positive tests
```

## How to Build & Test

```bash
# from workspace root
forge build    # should compile succefilly
forge test -v  # runs the tests
```

The tests cover deposits, withdrawals, pause logic, owner-only functions, merkle root setting, receive behaviour, and the multi-sig timelock flow.

## Results

- Contract compiles cleanly.
- 8/8 tests pass.
- All listed vulnerabilities are patched.


## License

MIT



