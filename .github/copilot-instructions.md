# GitHub Copilot Instructions

## Language and Communication

- **Always write code, comments, and documentation in English**
- Use clear, descriptive variable and function names in English
- Write commit messages in English following conventional commit format
- All code comments must be in English, regardless of the original repository language

## Code Style and Best Practices

### General Guidelines

- Follow POSIX-compliant shell scripting standards for shell scripts
- Use consistent indentation (2 spaces for shell scripts, 4 spaces for Python)
- Keep functions focused and single-purpose
- Prefer readability over cleverness
- Add comments only when they add value (explain "why", not "what")

### Shell Script Best Practices

- Always use `set -eu` at the beginning of scripts for error handling
- Quote variables to prevent word splitting: `"$var"` instead of `$var`
- Use `$()` for command substitution instead of backticks
- Check for command existence with `command -v` instead of `which`
- Use `mktemp` for temporary files and clean them up in trap handlers
- Validate required environment variables early in the script
- Use meaningful error messages with proper internationalization (i18n) for user-facing messages
  - Note: Code and comments must be in English; i18n applies only to runtime user messages

### Python Best Practices

- Follow PEP 8 style guidelines (4 spaces for indentation)
- Use type hints where appropriate
- Handle exceptions gracefully with specific error messages
- Use context managers (`with` statements) for file operations
- Keep Python snippets simple and focused for shell script integration

### Security Best Practices

- Never hardcode credentials or API tokens in code
- Use environment variables or configuration files for sensitive data
- Validate and sanitize user input
- Use secure communication (HTTPS) for API calls
- Implement proper retry logic with exponential backoff for network requests
- Set appropriate timeouts for network operations

## Code Review Guidelines

When reviewing code, always check for:

### Functionality
- Does the code solve the intended problem?
- Are edge cases handled properly?
- Is error handling comprehensive and appropriate?

### Code Quality
- Is the code readable and maintainable?
- Are variable and function names descriptive?
- Is the code properly documented where necessary?
- Are there any code smells or anti-patterns?

### Performance
- Are there any obvious performance issues?
- Is resource usage (memory, file handles, network) managed properly?
- Are there unnecessary operations or redundant code?

### Security
- Are there any security vulnerabilities?
- Is user input properly validated?
- Are credentials and sensitive data handled securely?
- Are dependencies up to date and free of known vulnerabilities?

### Testing
- Is the code testable?
- Are edge cases covered?
- Are error conditions tested?

### Compatibility
- Is the code compatible with the target environment (POSIX shell, Python 3, etc.)?
- Are all dependencies properly documented?
- Does the code work across different platforms if needed?

## Project-Specific Guidelines

### Confluence Uploader Script

- Maintain i18n support (English and German messages)
- Preserve POSIX compatibility (avoid bash-specific features)
- Keep retry logic and timeout configurations
- Maintain backward compatibility with existing configuration files
- Use Confluence REST API best practices
- Handle API rate limiting gracefully

### Error Handling

- Use the `msg()` function for internationalized error messages
- Use `die()` for fatal errors that should terminate the script
- Use `warn()` for non-fatal warnings
- Use `say()` for informational messages
- Provide actionable error messages that help users resolve issues

### Documentation

- Update README.md when adding new features or changing behavior
- Document environment variables in `.env.example` files
- Include usage examples for new functionality
- Keep inline documentation up to date with code changes

## Commit Guidelines

- Use conventional commit format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `refactor:` for code refactoring
  - `test:` for adding or updating tests
  - `chore:` for maintenance tasks
- Write clear, concise commit messages
- Reference issue numbers when applicable
- Keep commits focused on a single change

## Pull Request Guidelines

- Provide a clear description of the changes
- Link to related issues
- Include testing steps
- Highlight any breaking changes
- Update documentation as needed
- Ensure all CI checks pass before requesting review
