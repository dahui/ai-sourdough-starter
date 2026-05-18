// Package hello is a sample package shipped with the starter.
// Replace its contents (or remove it entirely) once real code lives here.
package hello

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

// ErrEmptyName is returned when Greet is called with an empty or
// whitespace-only name.
var ErrEmptyName = errors.New("hello: name must not be empty")

// Greet returns a greeting for the given name. Returns ErrEmptyName if name
// is empty or whitespace-only. Respects context cancellation.
func Greet(ctx context.Context, name string) (string, error) {
	if err := ctx.Err(); err != nil {
		return "", fmt.Errorf("greet: %w", err)
	}
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return "", ErrEmptyName
	}
	return fmt.Sprintf("Hello, %s!", trimmed), nil
}
