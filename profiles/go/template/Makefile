.PHONY: help build run test coverage lint format fmt vuln clean ship-check install-tools

BINARY := {{ project_slug }}
COVER_OUT := cover.out
COVER_THRESHOLD := 85

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile the binary
	@go build ./...

run: ## Run the binary
	@go run ./cmd/$(BINARY)

test: ## Run all tests with race detector and coverage
	@go test -race -coverprofile=$(COVER_OUT) ./...

coverage: test ## Enforce coverage threshold ($(COVER_THRESHOLD)%)
	@./scripts/check-coverage.sh $(COVER_OUT) $(COVER_THRESHOLD)

lint: ## Run golangci-lint
	@golangci-lint run

format: ## Run formatters
	@gofmt -w .
	@command -v goimports >/dev/null 2>&1 && goimports -w . || true

fmt: format ## Alias for format

vuln: ## Run govulncheck
	@govulncheck ./...

clean: ## Remove build artifacts
	@rm -f $(COVER_OUT) coverage.html
	@go clean ./...

ship-check: lint coverage vuln ## Full pre-flight (matches CI)
	@echo "READY TO SHIP"

install-tools: ## Install required dev tools
	@go install golang.org/x/vuln/cmd/govulncheck@latest
	@go install golang.org/x/tools/cmd/goimports@latest
	@command -v golangci-lint >/dev/null 2>&1 || { \
	  echo "Install golangci-lint: https://golangci-lint.run/welcome/install/"; \
	  exit 1; \
	}
