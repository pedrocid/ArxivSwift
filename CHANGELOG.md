# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-09-04

### Added
- Linux support (tested on Ubuntu 22.04/24.04)
- Linux CI workflow using `swift:6.1-jammy` container
- README section detailing Linux usage/build instructions

### Changed
- Project now targets Swift 6.1+
- Xcode requirement updated to 16.0+

## [1.0.0] - 2024-01-01

### Added
- Initial release of ArxivSwift
- Modern Swift API client for arXiv.org with async/await support
- Type-safe query building with fluent API
- Comprehensive data models for papers, authors, categories, and links
- Detailed error handling with recovery suggestions
- XML parsing for arXiv's Atom feed responses
- Convenience methods for common search operations
- Complete unit and integration test suite
- Comprehensive README with usage examples
- MIT License

### Features
- **ArxivClient**: Main client for API interactions
- **ArxivQuery**: Builder pattern for constructing queries
- **ArxivEntry**: Rich model representing arXiv papers
- **ArxivAuthor**: Author information and metadata
- **ArxivCategory**: Subject classification system
- **ArxivLink**: Associated links (PDF, abstract, etc.)
- **ArxivError**: Comprehensive error types

### Supported Platforms
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Swift 5.9+

[Unreleased]: https://github.com/pedrocid/ArxivSwift/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/pedrocid/ArxivSwift/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pedrocid/ArxivSwift/releases/tag/v1.0.0
