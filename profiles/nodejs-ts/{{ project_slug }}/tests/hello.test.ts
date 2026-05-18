import { describe, expect, it } from 'vitest';
import { EmptyNameError, greet } from '../src/hello.js';

describe('greet', () => {
  it('returns a formatted greeting for a plain name', () => {
    expect(greet('world')).toBe('Hello, world!');
  });

  it('trims leading and trailing whitespace', () => {
    expect(greet('  Ada  ')).toBe('Hello, Ada!');
  });

  it('throws EmptyNameError on empty string', () => {
    expect(() => greet('')).toThrow(EmptyNameError);
  });

  it('throws EmptyNameError on whitespace-only string', () => {
    expect(() => greet('   \t\n')).toThrow(EmptyNameError);
  });

  it('EmptyNameError has the expected name', () => {
    try {
      greet('');
    } catch (err) {
      expect(err).toBeInstanceOf(EmptyNameError);
      expect((err as Error).name).toBe('EmptyNameError');
    }
  });
});
