# Contributing to Simple Log Service

Thank you for your interest in contributing to the Simple Log Service! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (AWS region, Terraform version, Python version)
- Relevant logs or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome! Please create an issue with:
- Clear description of the enhancement
- Use case and benefits
- Potential implementation approach
- Any breaking changes

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-org/simple-log-service.git
   cd simple-log-service
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards below
   - Add tests for new functionality
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Run unit tests
   cd lambda/ingest/tests
   python -m pytest test_ingest.py
   
   cd ../../read_recent/tests
   python -m pytest test_read_recent.py
   
   # Run Terraform validation
   cd ../../../terraform
   terraform init
   terraform validate
   terraform fmt -check
   
   # Run integration tests
   cd ..
   ./scripts/test_service.sh
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```
   
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `test:` Test additions or changes
   - `refactor:` Code refactoring
   - `chore:` Maintenance tasks

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Ensure CI checks pass

## Coding Standards

### Terraform

- Use consistent formatting: `terraform fmt`
- Use meaningful resource names
- Add comments for complex logic
- Use variables for configurable values
- Follow AWS naming conventions
- Tag all resources appropriately

Example:
```hcl
resource "aws_dynamodb_table" "log_entries" {
  name           = "${var.project_name}-entries"
  billing_mode   = "PAY_PER_REQUEST"
  
  # Primary key design for efficient queries
  hash_key       = "id"
  range_key      = "datetime"
  
  tags = {
    Name = "${var.project_name}-table"
  }
}
```

### Python

- Follow PEP 8 style guide
- Use type hints where appropriate
- Add docstrings for functions
- Handle exceptions gracefully
- Use meaningful variable names
- Keep functions focused and small

Example:
```python
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for ingesting log entries.
    
    Args:
        event: Lambda event containing request body
        context: Lambda context object
        
    Returns:
        API Gateway response with status code and body
    """
    try:
        # Implementation
        pass
    except Exception as e:
        return create_response(500, {'error': str(e)})
```

### Documentation

- Use Markdown for all documentation
- Keep README.md up to date
- Document all configuration options
- Provide examples for common use cases
- Update CHANGELOG.md for all changes

## Testing Requirements

### Unit Tests
- Write tests for all Lambda functions
- Aim for >80% code coverage
- Mock external dependencies (DynamoDB, KMS)
- Test both success and error cases

### Integration Tests
- Test end-to-end workflows
- Verify AWS resource creation
- Test IAM authentication
- Validate compliance rules

### Security Tests
- Test IAM permission boundaries
- Verify encryption at rest and in transit
- Test input validation
- Check for security vulnerabilities

## Documentation Requirements

When adding new features, update:
- README.md (if user-facing)
- ARCHITECTURE.md (if architectural changes)
- SECURITY.md (if security-related)
- API.md (if API changes)
- TROUBLESHOOTING.md (if new issues identified)

## Review Process

1. **Automated Checks**
   - GitHub Actions runs Terraform validation
   - Code formatting checks
   - Security scanning

2. **Code Review**
   - At least one approval required
   - Address all review comments
   - Maintain respectful communication

3. **Testing**
   - All tests must pass
   - Manual testing in dev environment
   - Performance impact assessment

4. **Documentation Review**
   - Documentation is clear and complete
   - Examples are accurate
   - No broken links

## Release Process

1. Update CHANGELOG.md
2. Update version numbers
3. Create release branch
4. Run full test suite
5. Deploy to staging environment
6. Perform smoke tests
7. Create GitHub release
8. Deploy to production
9. Monitor for issues

## Getting Help

- Create an issue for questions
- Join our Slack channel (if available)
- Email maintainers (if urgent)
- Check existing documentation first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- GitHub contributors page

Thank you for contributing to Simple Log Service!

