package hello_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"{{ module_path }}/internal/hello"
)

func TestGreet_Success(t *testing.T) {
	t.Parallel()

	got, err := hello.Greet(context.Background(), "world")
	require.NoError(t, err)
	assert.Equal(t, "Hello, world!", got)
}

func TestGreet_TrimsWhitespace(t *testing.T) {
	t.Parallel()

	got, err := hello.Greet(context.Background(), "  Ada  ")
	require.NoError(t, err)
	assert.Equal(t, "Hello, Ada!", got)
}

func TestGreet_EmptyName(t *testing.T) {
	t.Parallel()

	_, err := hello.Greet(context.Background(), "")
	require.Error(t, err)
	assert.True(t, errors.Is(err, hello.ErrEmptyName), "expected ErrEmptyName")
}

func TestGreet_WhitespaceOnlyName(t *testing.T) {
	t.Parallel()

	_, err := hello.Greet(context.Background(), "   \t\n")
	require.Error(t, err)
	assert.True(t, errors.Is(err, hello.ErrEmptyName), "expected ErrEmptyName")
}

func TestGreet_RespectsCancellation(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := hello.Greet(ctx, "anyone")
	require.Error(t, err)
	assert.True(t, errors.Is(err, context.Canceled))
}

func TestGreet_RespectsDeadline(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(-time.Second))
	defer cancel()

	_, err := hello.Greet(ctx, "anyone")
	require.Error(t, err)
	assert.True(t, errors.Is(err, context.DeadlineExceeded))
}
