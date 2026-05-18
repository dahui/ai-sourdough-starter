/** Sample module shipped with the starter. Replace once real code lives here. */

export class EmptyNameError extends Error {
  constructor() {
    super('name must not be empty');
    this.name = 'EmptyNameError';
  }
}

/**
 * Returns a greeting for the given name.
 *
 * @throws {EmptyNameError} if name is empty or whitespace-only
 */
export function greet(name: string): string {
  const trimmed = name.trim();
  if (trimmed === '') {
    throw new EmptyNameError();
  }
  return `Hello, ${trimmed}!`;
}
