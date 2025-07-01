# Contributing to ArxivSwift

Thank you for your interest in contributing to ArxivSwift! This document provides guidelines for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Documentation](#documentation)

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/ArxivSwift.git
   cd ArxivSwift
   ```
3. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Requirements
- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 12.0 or later for development

### Building the Project
```bash
# Build the package
swift build

# Run tests
swift test

# Generate documentation (if DocC is available)
swift package generate-documentation
```

## Making Changes

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes**: Fix issues in existing functionality
- **New features**: Add new capabilities to the library
- **Documentation**: Improve or add documentation
- **Tests**: Add or improve test coverage
- **Performance**: Optimize existing code

### Before You Start

1. Check existing issues to see if your bug or feature request already exists
2. For major changes, consider opening an issue first to discuss the approach
3. Keep changes focused and atomic - one feature or fix per PR

### Development Guidelines

1. **Follow Swift conventions**: Use standard Swift naming and style conventions
2. **Write tests**: All new features should include comprehensive tests
3. **Document your code**: Add DocC-style documentation comments for public APIs
4. **Handle errors appropriately**: Use the existing `ArxivError` enum for error cases
5. **Maintain async/await patterns**: Keep the modern concurrency approach consistent

## Testing

The project uses Swift Testing framework. Make sure all tests pass before submitting:

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test suite
swift test --filter ArxivClientTests
```

### Test Guidelines

- Write unit tests for all new functionality
- Include integration tests for API interactions when appropriate
- Mock external dependencies where possible
- Test error conditions and edge cases
- Ensure tests are deterministic and don't rely on external state

## Submitting Changes

### Pull Request Process

1. Ensure your code builds and all tests pass
2. Update documentation if you've changed APIs
3. Update CHANGELOG.md with your changes
4. Submit a pull request with:
   - Clear title describing the change
   - Detailed description of what was changed and why
   - Reference any related issues

### Pull Request Template

```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests pass

## Checklist
- [ ] Code follows the project's style guidelines
- [ ] Self-review of code completed
- [ ] Code is properly documented
- [ ] CHANGELOG.md updated
```

## Code Style

### Swift Style Guidelines

- Use 4 spaces for indentation
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Keep functions focused and concise
- Group related functionality with `// MARK:` comments

### Documentation Style

Use DocC-style documentation comments for all public APIs:

```swift
/// Brief description of the function
/// 
/// Longer description if needed, explaining the purpose,
/// behavior, and any important details.
///
/// - Parameters:
///   - parameter1: Description of parameter1
///   - parameter2: Description of parameter2
/// - Returns: Description of return value
/// - Throws: Description of errors that can be thrown
public func exampleFunction(parameter1: String, parameter2: Int) async throws -> String {
    // Implementation
}
```

## Documentation

### Types of Documentation

1. **Code Documentation**: DocC comments for all public APIs
2. **README**: Keep the main README updated with new features
3. **Examples**: Add practical examples for new functionality
4. **Changelog**: Document all changes in CHANGELOG.md

### Documentation Standards

- All public APIs must be documented
- Include practical examples in documentation
- Explain complex algorithms or business logic
- Document error conditions and recovery strategies
- Keep documentation up-to-date with code changes

## Questions or Issues?

If you have questions about contributing:

1. Check existing documentation and issues
2. Open a new issue for discussion
3. Reach out to maintainers if needed

Thank you for contributing to ArxivSwift!