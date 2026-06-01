# Gulflands Operating System

## Overview

This document provides comprehensive setup instructions, development workflows, and operational procedures for the Gulflands project. Following these procedures ensures consistent, high-quality contributions and reliable deployments.

## Prerequisites

### System Requirements

- **Operating System:** Windows 10/11, macOS 12+, or Ubuntu 20.04+
- **RAM:** Minimum 8GB, Recommended 16GB+
- **Storage:** 20GB free space
- **Internet:** Stable broadband connection

### Development Tools

#### Flutter Development
- Flutter SDK: 3.8.1 or later
- Dart SDK: 3.0.0 or later
- Android Studio / VS Code with Flutter extensions
- Android SDK (API 21+) or Xcode (for iOS development)

#### Backend Development
- PHP: 8.1 or later
- Composer: Latest stable
- Python: 3.9 or later
- pip: Latest stable
- Node.js: 18.x or later (for tooling)

#### Database & Tools
- MySQL 8.0 or PostgreSQL 13+
- Docker Desktop 4.0+
- Git: 2.30+

## Project Setup

### 1. Repository Setup

```bash
# Clone the repository
git clone https://github.com/your-org/gulflands.git
cd gulflands

# Verify branch
git branch -a
git checkout develop
```

### 2. Environment Configuration

#### Flutter Setup

```bash
# Install Flutter dependencies
flutter pub get

# Generate code (for freezed, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
```

#### PHP Backend Setup

```bash
cd backend-php

# Install PHP dependencies
composer install

# Copy environment configuration
cp .env.example .env

# Edit .env with your database credentials
# DB_HOST=localhost
# DB_NAME=gulflands
# DB_USER=your_user
# DB_PASS=your_password
```

#### Python Analytics Setup

```bash
cd backend-python

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment configuration
cp .env.example .env
# Edit .env with necessary configurations
```

#### Database Setup

```bash
# Using Docker (recommended)
docker run --name gulflands-db -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=gulflands -p 3306:3306 -d mysql:8.0

# Or using local MySQL installation
mysql -u root -p
CREATE DATABASE gulflands;
# Run migrations from backend-php/migrations/
```

### 3. Docker Development Environment

```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Initial Data Seeding

```bash
# PHP Backend
cd backend-php
php artisan migrate
php artisan db:seed

# Python Analytics
cd backend-python
python main.py --seed
```

## Development Workflows

### Daily Development Cycle

#### 1. Start Development

```bash
# Pull latest changes
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/GULF-123-user-authentication
```

#### 2. Code Development

```bash
# Flutter development
flutter run  # For mobile development
flutter run -d chrome  # For web development

# Backend development
# PHP: Use your preferred PHP server or Docker
# Python: python main.py

# Run tests frequently
flutter test
cd backend-php && composer test
cd backend-python && python -m pytest
```

#### 3. Code Quality Checks

```bash
# Flutter
flutter analyze
flutter format .

# PHP
cd backend-php
./vendor/bin/phpcs
./vendor/bin/phpmd src text codesize,unusedcode,naming

# Python
cd backend-python
flake8 .
black .
mypy .
```

#### 4. Commit and Push

```bash
# Stage changes
git add .

# Commit with conventional format
git commit -m "feat: implement user authentication

- Add login form with validation
- Implement JWT token handling
- Add logout functionality

Closes GULF-123"

# Push to remote
git push origin feature/GULF-123-user-authentication
```

#### 5. Create Pull Request

1. Navigate to GitHub repository
2. Click "New Pull Request"
3. Select your feature branch
4. Fill PR template:
   - **Title:** [GULF-123] Implement user authentication
   - **Description:** Detailed description of changes
   - **Checklist:** Verify all done-criteria met
5. Request reviews from at least 2 team members

### Testing Strategy

#### Unit Testing

```bash
# Flutter
flutter test --coverage

# PHP
cd backend-php
./vendor/bin/phpunit --coverage-html coverage

# Python
cd backend-python
python -m pytest --cov=. --cov-report=html
```

#### Integration Testing

```bash
# End-to-end tests
flutter drive --target=test_driver/app.dart

# API integration tests
cd backend-php
./vendor/bin/phpunit tests/Integration/

# Full system tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

#### Performance Testing

```bash
# Flutter performance
flutter run --profile

# Backend load testing
ab -n 1000 -c 10 http://localhost:8000/api/land-plots

# Memory leak detection
# Use Flutter DevTools or Xcode Instruments
```

### Deployment Workflow

#### Staging Deployment

```bash
# Create release branch
git checkout develop
git pull origin develop
git checkout -b release/v1.2.0

# Update version numbers
# Update pubspec.yaml, composer.json, etc.

# Run full test suite
./scripts/run-full-tests.sh

# Deploy to staging
./scripts/deploy-staging.sh
```

#### Production Deployment

```bash
# Merge release to main
git checkout main
git merge release/v1.2.0

# Create git tag
git tag v1.2.0
git push origin main --tags

# Deploy to production
./scripts/deploy-production.sh

# Monitor deployment
# Check logs, metrics, error rates
```

## Contribution Guidelines

### Code Style Standards

#### Flutter/Dart

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_const_declarations
    - unnecessary_null_checks
    - prefer_final_fields
```

#### PHP

```xml
<!-- phpcs.xml -->
<?xml version="1.0"?>
<ruleset name="Gulflands">
    <rule ref="PSR12"/>
    <rule ref="Generic.Arrays.DisallowLongArraySyntax"/>
    <rule ref="Generic.CodeAnalysis.UnusedFunctionParameter"/>
</ruleset>
```

#### Python

```ini
# setup.cfg
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .git,__pycache__,build,dist

[tool:black]
line-length = 88
target-version = ['py39']
include = \.pyi?$

[tool:mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
```

### Commit Message Convention

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

**Examples:**
```
feat(auth): implement JWT authentication

- Add login endpoint
- Implement token refresh
- Add middleware for protected routes

Closes GULF-123
```

### Issue Tracking

#### Issue Creation Template

```markdown
## Issue Summary
[Brief description of the issue]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Environment
- OS: [Windows/macOS/Linux]
- Browser: [Chrome/Firefox/Safari]
- Device: [Desktop/Mobile]

## Additional Context
[Screenshots, logs, related issues]
```

#### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation needed
- `good-first-issue`: Good for newcomers
- `help-wanted`: Extra attention needed
- `priority-high`: High priority
- `priority-medium`: Medium priority
- `priority-low`: Low priority

### Code Review Process

#### Reviewer Checklist

**Code Quality**
- [ ] Code follows established patterns
- [ ] No security vulnerabilities
- [ ] Performance considerations addressed
- [ ] Error handling appropriate

**Testing**
- [ ] Unit tests included
- [ ] Edge cases covered
- [ ] Integration tests if applicable

**Documentation**
- [ ] Code is self-documenting
- [ ] Comments added for complex logic
- [ ] Documentation updated

**Architecture**
- [ ] Follows established architecture
- [ ] No unnecessary dependencies
- [ ] Scalable design

#### Review Comments Guidelines

- **Praise:** Highlight good practices
- **Question:** Ask for clarification
- **Suggestion:** Propose improvements
- **Issue:** Point out problems that must be fixed

### Release Process

#### Version Numbering

Follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

#### Release Checklist

**Pre-Release**
- [ ] All features implemented and tested
- [ ] Documentation updated
- [ ] Breaking changes documented
- [ ] Migration guide prepared (if needed)

**Release**
- [ ] Version numbers updated in all files
- [ ] Changelog updated
- [ ] Release branch created
- [ ] CI/CD pipeline passes

**Post-Release**
- [ ] Release notes published
- [ ] Stakeholders notified
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented

## Monitoring and Maintenance

### Health Checks

#### Application Health

```bash
# Flutter app health (manual testing)
# - App launches without crashes
# - Navigation works
# - API calls succeed

# Backend health
curl http://localhost:8000/health

# Database health
mysql -u root -p -e "SELECT 1"
```

#### Performance Monitoring

- **Response Times**: API endpoints < 200ms
- **Error Rates**: < 1% of requests
- **Memory Usage**: < 80% of available RAM
- **CPU Usage**: < 70% during normal operation

### Backup and Recovery

#### Database Backup

```bash
# Daily backup script
mysqldump -u root -p gulflands > backup_$(date +%Y%m%d).sql

# Automated backup (cron)
0 2 * * * /path/to/backup-script.sh
```

#### Code Repository

- All code changes committed and pushed
- Branches follow naming conventions
- Pull requests required for all changes
- Code reviews mandatory

### Incident Response

#### Incident Response Plan

1. **Detection**: Monitor alerts and logs
2. **Assessment**: Evaluate impact and urgency
3. **Communication**: Notify stakeholders
4. **Resolution**: Implement fix
5. **Post-Mortem**: Document lessons learned

#### Escalation Matrix

- **P1 (Critical)**: Service down - Immediate response
- **P2 (High)**: Major feature broken - < 4 hours
- **P3 (Medium)**: Minor issues - < 24 hours
- **P4 (Low)**: Cosmetic issues - Next sprint

## Security Guidelines

### Code Security

- Never commit secrets or credentials
- Use environment variables for configuration
- Implement input validation on all user inputs
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization

### Infrastructure Security

- Keep dependencies updated
- Use HTTPS for all communications
- Implement rate limiting
- Regular security audits
- Monitor for vulnerabilities

### Data Protection

- Encrypt sensitive data at rest
- Use secure communication protocols
- Implement proper access controls
- Regular backup encryption
- GDPR/CCPA compliance where applicable

## Troubleshooting

### Common Issues

#### Flutter Issues

**Build Failures**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**iOS Build Issues**
```bash
cd ios
pod install
flutter build ios
```

#### Backend Issues

**PHP Composer Issues**
```bash
rm -rf vendor/
composer clear-cache
composer install
```

**Python Virtual Environment Issues**
```bash
rm -rf venv/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Database Issues

**Connection Refused**
```bash
# Check if MySQL is running
sudo systemctl status mysql

# Restart if needed
sudo systemctl restart mysql
```

**Migration Failures**
```bash
# Rollback last migration
php artisan migrate:rollback

# Check migration status
php artisan migrate:status
```

### Getting Help

1. **Documentation**: Check this document first
2. **Team Chat**: Ask in development channel
3. **Issues**: Create GitHub issue with details
4. **Code Review**: Request help during PR review

### Support Contacts

- **Technical Lead**: [Name] - [Email]
- **DevOps**: [Name] - [Email]
- **Security**: [Name] - [Email]
- **Product**: [Name] - [Email]