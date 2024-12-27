.PHONY: build clean test vet

# Build the application
build:
	go build -v ./cmd/cursor-id-modifier

# Clean build artifacts
clean:
	rm -f cursor-id-modifier
	go clean

# Run tests
test:
	go test -v ./...

# Run go vet
vet:
	go vet ./...

# Run all checks
all: vet test build 