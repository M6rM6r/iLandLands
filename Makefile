.PHONY: setup setup-flutter setup-php setup-python analyze analyze-flutter analyze-php analyze-python test test-flutter test-php test-python build help format lint lint-php build-web deploy-web

SHELL := /bin/bash
FLUTTER := flutter
PHP := php
PYTHON := python3

help:
	@echo "Gulflands Management Interface"
	@echo "setup    : Install all dependencies across stacks"
	@echo "analyze  : Execute high-rigor static analysis"
	@echo "test     : Run comprehensive test suites"
	@echo "clean    : Remove build artifacts"
	@echo "format   : Apply strict formatting"
	@echo "lint-php : Check PHP code style (dry-run)"
	@echo "build-web: Build Flutter Web application for release"
	@echo "deploy-web: Deploy Flutter Web application to Firebase Hosting"

clean:
	$(FLUTTER) clean
	rm -rf build/
	rm -rf coverage/

format:
	$(FLUTTER) format .
	cd backend && ./vendor/bin/php-cs-fixer fix
	cd backend-python && black . && ruff format .

lint: analyze

lint-php:
	cd backend && ./vendor/bin/php-cs-fixer fix --dry-run --diff

build-web:
	$(FLUTTER) build web --release

deploy-web:
	firebase deploy --only hosting

setup-flutter:
	$(FLUTTER) pub get

setup-php:
	cd backend && composer install --no-progress --no-interaction

setup-python:
	cd backend-python && $(PYTHON) -m venv venv && source venv/bin/activate && pip install -r requirements.txt

setup: setup-flutter setup-php setup-python

analyze-flutter:
	@echo "Auditing Dart..."
	$(FLUTTER) analyze

analyze-php:
	@echo "Auditing PHP (Level 9)..."
	cd backend && ./vendor/bin/phpstan analyze -l 9 src

analyze-python:
	@echo "Auditing Python (Strict MyPy)..."
	cd backend-python && mypy . --strict

analyze: analyze-flutter analyze-php analyze-python

test-flutter:
	$(FLUTTER) test --coverage

test-php:
	cd backend && ./vendor/bin/phpunit --coverage-clover=coverage.xml

test-python:
	cd backend-python && pytest

test: test-flutter test-php test-python

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

build-runner:
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs