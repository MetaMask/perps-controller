# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial snapshot of PerpsController from MetaMask Mobile
  - Protocol-agnostic perpetuals trading controller with `PerpsPlatformDependencies` for dependency injection
  - HyperLiquid and MYX provider implementations
  - Full service layer (AccountService, TradingService, MarketDataService, EligibilityService, DepositService, DataLakeService, RewardsIntegrationService, FeatureFlagConfigurationService)
  - HTTP clients (HyperLiquidClientService, MYXClientService)
  - WebSocket subscription management (HyperLiquidSubscriptionService)
  - Wallet integration (HyperLiquidWalletService)
  - Multi-provider aggregation via AggregatedPerpsProvider and ProviderRouter
  - Selector functions for state access
  - TradingReadinessCache for cached readiness state

[Unreleased]: https://github.com/MetaMask/perps-controller/
