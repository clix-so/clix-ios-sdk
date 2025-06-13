# Contributing to Clix iOS SDK

We love your input! We want to make contributing to Clix iOS SDK as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Pull Request Process

1. Update the README.md with details of changes to the interface, if applicable.
2. Update the documentation with details of any new environment variables, exposed ports, useful file locations and container parameters.
3. The PR will be merged once you have the sign-off of at least one other developer.

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using GitHub's [issue tracker](https://github.com/clix-so/clix-ios-sdk/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/clix-so/clix-ios-sdk/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can.
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Code Style & Linting

This project uses SwiftFormat and SwiftLint to enforce code style and maintain code quality. Please ensure your contributions adhere to these standards before submitting a pull request.

**Prerequisites:**

Make sure you have SwiftFormat and SwiftLint installed. You can install them using Homebrew:

```bash
brew install swift-format swiftlint
```

**Running the Tools:**

We provide a `Makefile` to simplify running these tools. Use the following commands from the project root directory:

- `make format`: Automatically formats all Swift code in the project using the rules defined in `.swift-format`.
- `make lint`: Lints the codebase using SwiftLint based on the rules in `.swiftlint.yml`. Reports warnings or errors.
- `make lint-fix`: Attempts to automatically fix linting issues found by SwiftLint.
- `make all`: Runs both `format` and `lint` targets sequentially.

**Before Submitting:**

Please run `make format` and `make lint-fix` first, then review any remaining issues reported by `make lint`. Resolve all issues before creating a pull request to ensure a smooth review process.

## License

By contributing, you agree that your contributions will be licensed under its MIT License. 
