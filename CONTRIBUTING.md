# Contributing to AWS Cost Forecast Toolkit

Thank you for your interest in contributing to the AWS Cost Forecast Toolkit! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

We welcome contributions from the AWS community! Here are several ways you can help:

### 🐛 Bug Reports
- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml)
- Include detailed steps to reproduce the issue
- Provide your environment details (OS, AWS CLI version, etc.)
- Include relevant log files or error messages

### 💡 Feature Requests
- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml)
- Clearly describe the problem you're trying to solve
- Explain how the feature would benefit other users
- Consider providing a basic implementation outline

### 📖 Documentation Improvements
- Fix typos, grammar, or unclear explanations
- Add examples or use cases
- Improve installation or setup instructions
- Translate documentation to other languages

### 🔧 Code Contributions
- Bug fixes
- New features
- Performance improvements
- Code quality enhancements

## 🚀 Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- Basic knowledge of Bash scripting
- Familiarity with AWS Cost Explorer and QuickSight

### Development Setup

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/aws-cost-forecast-toolkit.git
   cd aws-cost-forecast-toolkit
   ```

3. **Set up the development environment**
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   
   # Run setup to check prerequisites
   ./scripts/setup.sh --check-only
   ```

4. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Guidelines

### Code Style

#### Shell Scripts
- Use `#!/bin/bash` shebang
- Enable strict error handling: `set -euo pipefail`
- Use meaningful variable names with `readonly` for constants
- Add comments for complex logic
- Follow the existing code structure and patterns

#### Example:
```bash
#!/bin/bash
# Brief description of the script
# Author: Your Name
# License: MIT

set -euo pipefail

# Constants
readonly SCRIPT_VERSION="1.0.0"
readonly OUTPUT_DIR="/tmp/output"

# Functions
log() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${level}] ${message}"
}

# Main execution
main() {
    log "INFO" "Starting script execution"
    # Your code here
}

main "$@"
```

### Testing

#### Manual Testing
1. Test in AWS CloudShell environment
2. Test with different AWS regions
3. Test with various Cost Explorer permissions
4. Verify QuickSight integration works

#### Automated Testing
```bash
# Run shell script linting
shellcheck scripts/*.sh

# Run basic functionality tests
./tests/run-tests.sh

# Test setup script
./scripts/setup.sh --check-only
```

### Documentation
- Update README.md if adding new features
- Add inline comments for complex logic
- Update help text and usage examples
- Include examples in the `examples/` directory

## 🔄 Pull Request Process

### Before Submitting
1. **Test thoroughly** in AWS CloudShell
2. **Run linting** with shellcheck
3. **Update documentation** as needed
4. **Add examples** if introducing new features
5. **Check for breaking changes**

### Pull Request Guidelines

1. **Create a descriptive title**
   - ✅ "Add support for custom date ranges in forecast script"
   - ❌ "Fix bug"

2. **Write a detailed description**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Performance improvement
   
   ## Testing
   - [ ] Tested in AWS CloudShell
   - [ ] Tested with different AWS regions
   - [ ] Updated documentation
   
   ## Screenshots (if applicable)
   Add screenshots of new features or UI changes
   ```

3. **Link related issues**
   - Use "Fixes #123" or "Closes #123" to auto-close issues

4. **Keep changes focused**
   - One feature or fix per PR
   - Avoid mixing unrelated changes

### Review Process
1. **Automated checks** must pass
2. **Manual review** by maintainers
3. **Testing** in different environments
4. **Documentation review**
5. **Approval** and merge

## 🏷️ Commit Guidelines

### Commit Message Format
```
type(scope): brief description

Detailed explanation if needed

Fixes #123
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```bash
feat(forecast): add support for custom date ranges

Allow users to specify custom start and end dates for forecasting
instead of only predefined periods.

Fixes #45

fix(quicksight): handle missing S3 permissions gracefully

Add proper error handling when S3 bucket access is denied,
providing clear instructions to users.

docs(readme): update installation instructions for macOS

Add specific instructions for macOS users including Homebrew
installation steps.
```

## 🧪 Testing Guidelines

### Test Categories

#### Unit Tests
- Test individual functions
- Mock AWS API calls when possible
- Use BATS (Bash Automated Testing System)

#### Integration Tests
- Test with real AWS services
- Use test AWS accounts
- Clean up resources after testing

#### Manual Testing Checklist
- [ ] Script runs without errors in CloudShell
- [ ] All interactive prompts work correctly
- [ ] Output files are generated properly
- [ ] S3 upload functionality works
- [ ] QuickSight manifest is valid
- [ ] Error handling works as expected
- [ ] Help text is accurate and helpful

### Test Environment Setup
```bash
# Set up test environment
export AWS_PROFILE=test-profile
export TEST_S3_BUCKET=test-forecast-bucket

# Run tests
./tests/run-tests.sh
```

## 📋 Issue Guidelines

### Before Creating an Issue
1. **Search existing issues** to avoid duplicates
2. **Check documentation** for solutions
3. **Test with latest version**

### Issue Types

#### Bug Reports
Include:
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Error messages/logs
- Screenshots if applicable

#### Feature Requests
Include:
- Problem description
- Proposed solution
- Use cases
- Implementation ideas (optional)

#### Questions
- Check documentation first
- Use GitHub Discussions for general questions
- Be specific about your use case

## 🏆 Recognition

### Contributors
We recognize contributors in several ways:
- Listed in README.md
- GitHub contributor statistics
- Special mentions in release notes
- Community recognition

### Contribution Types
- 🐛 Bug fixes
- ✨ New features
- 📖 Documentation
- 🎨 Design/UX improvements
- 🔧 Infrastructure/tooling
- 🌍 Translations
- 💡 Ideas and feedback

## 📞 Getting Help

### Community Support
- 💬 [GitHub Discussions](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/discussions)
- 🐛 [GitHub Issues](https://github.com/NithinChandranR-AWS/aws-cost-forecast-toolkit/issues)

### Direct Contact
- 📧 Email: rajashan@amazon.com
- 💼 LinkedIn: [Nithin Chandran R](https://www.linkedin.com/in/nithin-chandran-r/)

## 📜 Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

### Our Standards
- **Be respectful** and inclusive
- **Be collaborative** and helpful
- **Be patient** with newcomers
- **Be constructive** in feedback
- **Focus on the community** benefit

## 🎯 Roadmap Contributions

We welcome contributions to our roadmap items:

### High Priority
- [ ] Multi-cloud support (Azure, GCP)
- [ ] Machine learning predictions
- [ ] Slack/Teams integration

### Medium Priority
- [ ] Terraform module
- [ ] API Gateway wrapper
- [ ] Mobile dashboard templates

### Community Requests
- [ ] Additional visualization templates
- [ ] Cost anomaly detection
- [ ] Budget threshold alerts

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to the AWS Cost Forecast Toolkit! Your contributions help make AWS cost management more accessible to the entire community. 🚀
