# GitHub Copilot Custom Instructions

## Code Generation Guidelines

### Language Requirements

- **All code and comments must be written in English**
- Use proper English grammar and spelling in all documentation
- Variable names, function names, and comments must be in English

### Variable Naming Standards

- **No single-letter variables** except for pure counters (i, j, k in loops)
- Use descriptive, meaningful names that explain the purpose
- Follow language-specific naming conventions:
  - Python: `snake_case` for variables and functions
  - JavaScript/TypeScript: `camelCase` for variables and functions
  - Constants: `UPPER_SNAKE_CASE`

Examples:

```python
# ❌ Bad
x = get_data()
d = datetime.now()

# ✅ Good
user_data = get_user_data()
current_timestamp = datetime.now()
```

### Comment Standards

- **Explain WHY, not WHAT** the code does
- Write comments that explain business logic, decisions, and context
- Avoid obvious comments that just restate the code
- Use proper English grammar in comments

Examples:

```python
# ❌ Bad - explains what
user_id = request.get('user_id')  # Get user ID from request

# ✅ Good - explains why
user_id = request.get('user_id')  # Required for audit trail and authorization
```

### Language-Specific Best Practices

#### Python

- Follow PEP 8 style guidelines
- Use consistent indentation (4 spaces for Python)
- Use type hints for function parameters and return values
- Write docstrings for classes and functions
- Use context managers (`with` statements) for resource management
- Handle exceptions gracefully with specific error messages

#### JavaScript/TypeScript

- Use `const` by default, `let` when reassignment is needed
- Prefer arrow functions for callbacks
- Use async/await over Promises when possible
- Include proper JSDoc comments for functions

#### Shell Scripts

- Use `set -eu` for error handling (POSIX compliance)
- Quote variables to prevent word splitting: `"$var"` instead of `$var`
- Use `$()` for command substitution instead of backticks
- Check for command existence with `command -v` instead of `which`
- Use `mktemp` for temporary files and clean them up in trap handlers
- Follow POSIX standards when possible (avoid bash-specific features)
- Use consistent indentation (2 spaces for shell scripts)
- Use meaningful function names and comments

#### YAML (GitHub Actions)

- Use descriptive step names
- Add comments explaining complex workflows
- Group related steps logically
- Use meaningful variable names in environment sections

### Security Considerations

- Never include sensitive data in code or comments
- Use environment variables for configuration
- Add comments explaining security decisions
- Follow principle of least privilege
- Never hardcode credentials or API tokens in code
- Validate and sanitize user input
- Use secure communication (HTTPS) for API calls

### Error Handling Guidelines

- Use appropriate error handling functions when available:
  - `msg()` for internationalized error messages
  - `die()` for fatal errors that should terminate the script
  - `warn()` for non-fatal warnings
  - `say()` for informational messages
- Provide actionable error messages that help users resolve issues
- Handle exceptions gracefully with specific error messages

### Testing Standards

- Write descriptive test names that explain the scenario
- Include comments explaining complex test setups
- Use proper assertions with meaningful error messages
- Test edge cases and error conditions

## Commit Message Guidelines

All commit messages must follow **Conventional Commits** format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types:

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes
- `ci`: CI/CD changes

### Commit Best Practices:

- Write clear, concise commit messages in English
- Reference issue numbers when applicable
- Keep commits focused on a single change
- Use the imperative mood in the subject line

### Examples:

```
feat(auth): add OAuth2 authentication flow

fix: resolve memory leak in data processing

docs: update README with installation instructions

refactor(api): simplify user validation logic
```
