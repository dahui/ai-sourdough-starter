// Package main is the entry point for the {{ project_slug }} binary.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"{{ module_path }}/internal/hello"
)

func main() {
	if err := run(); err != nil {
		slog.Error("fatal", "err", err)
		os.Exit(1)
	}
}

func run() error {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	greeting, err := hello.Greet(ctx, "world")
	if err != nil {
		return fmt.Errorf("greet: %w", err)
	}

	if _, err := fmt.Println(greeting); err != nil {
		return errors.Join(err, fmt.Errorf("println"))
	}
	return nil
}
