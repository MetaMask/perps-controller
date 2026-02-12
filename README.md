# `@metamask/perps-controller`

Controller for perpetual trading functionality in MetaMask. This package is a **snapshot** of the PerpsController source from [MetaMask Mobile](https://github.com/MetaMask/metamask-mobile), published as a standalone npm package so that Extension and other clients can consume it.

## Architecture

Mobile is the **single source of truth** for the controller code (see [ADR-042](https://github.com/MetaMask/core/blob/main/docs/adr/ADR-042-perps-controller-location.md)). This repository does not contain original source — it syncs from `app/controllers/perps/` in the mobile repo and publishes to npm.

```
MetaMask Mobile (source of truth)
  app/controllers/perps/
        │
        │  yarn sync
        ▼
perps-controller (this repo)
  src/  ← snapshot copy (no tests, no mocks)
        │
        │  yarn build
        ▼
  dist/ → published to npm as @metamask/perps-controller
```

### What's included

- **PerpsController** — Main controller managing providers, orders, positions, market data
- **Providers** — HyperLiquid, MYX, and AggregatedPerpsProvider (multi-protocol)
- **Services** — AccountService, TradingService, MarketDataService, EligibilityService, DepositService, DataLakeService, RewardsIntegrationService, FeatureFlagConfigurationService, and more
- **Selectors** — Redux state selectors
- **Types** — Full TypeScript type definitions including `PerpsPlatformDependencies` for dependency injection

### What's NOT included

- Tests (run in mobile repo only)
- React components, hooks, views (stay in mobile's `app/components/UI/Perps/`)
- PerpsConnectionManager, PerpsStreamManager (mobile-specific, stay in UI layer)

## Installation

```bash
yarn add @metamask/perps-controller
```

## Syncing from Mobile

### First-time setup

```bash
git clone https://github.com/MetaMask/perps-controller.git
cd perps-controller
yarn install
```

### Sync workflow

```bash
# 1. Sync controller code from mobile
yarn sync -- --mobile-path /path/to/metamask-mobile

# 2. Build (verify TypeScript compilation)
yarn build

# 3. Generate changelog draft from mobile commits
yarn sync:changelog
```

The sync script:
1. Copies `app/controllers/perps/*` from mobile into `src/`, excluding tests and mocks
2. Validates no mobile-specific imports (`../../` paths) exist in the synced code
3. Updates `.sync-state.json` with the mobile commit hash, branch, and timestamp

### Sync options

```bash
# Sync from a specific branch
yarn sync -- --mobile-path /path/to/mobile --branch main

# Generate changelog (reads mobile path from .sync-state.json)
yarn sync:changelog

# Or specify mobile path explicitly
yarn sync:changelog -- --mobile-path /path/to/mobile
```

## Development

### Why a snapshot repo?

Metro's babel transformer skips `react-refresh/babel` instrumentation for any path containing `node_modules`. With the controller code living in mobile's `app/controllers/perps/` and aliased via `extraNodeModules` in `metro.config.js`, developers get true component-level Fast Refresh with React state preservation. A `cp to node_modules` workflow would lose this, causing full JS reloads and lost state — a significant DX cost when iterating on trading logic with open positions, WebSocket connections, and filled order forms.

### Linting

ESLint is configured to **ignore `src/`** — linting is done in the mobile repo where the source of truth lives. Only project config files (scripts, configs) are linted here.

### Build

```bash
yarn build        # TypeScript compilation via ts-bridge
```

### Validation checks

After syncing, verify:

```bash
# Build succeeds
yarn build

# No mobile-specific imports leaked through
grep -r "from '../../" src/
# (should return nothing)

# No test files synced
find src -name "*.test.ts"
# (should return nothing)
```

## Contributing

### Setup

- Install the current LTS version of [Node.js](https://nodejs.org)
  - If you are using [nvm](https://github.com/creationix/nvm#installation) (recommended) running `nvm install` will install the latest version and running `nvm use` will automatically choose the right node version for you.
- Install [Yarn](https://yarnpkg.com) v4 via [Corepack](https://github.com/nodejs/corepack?tab=readme-ov-file#how-to-install)
- Run `yarn install` to install dependencies

### Making changes to the controller

**Do not edit files in `src/` directly.** Changes must be made in the mobile repo and synced here. This ensures mobile remains the single source of truth.

1. Make changes in `metamask-mobile/app/controllers/perps/`
2. Verify in mobile: `npx eslint app/controllers/perps/` and `yarn jest app/controllers/perps/ --no-coverage`
3. Sync here: `yarn sync -- --mobile-path /path/to/mobile`
4. Build: `yarn build`
5. Update CHANGELOG.md (use `yarn sync:changelog` for a draft)

### Release & Publishing

The project follows the same release process as other MetaMask packages. See the [MetaMask release process](https://github.com/MetaMask/action-create-release-pr) for details.
