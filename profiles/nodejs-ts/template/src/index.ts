import { greet } from './hello.js';

function main(): void {
  // biome-ignore lint/suspicious/noConsoleLog: entry point output is intentional
  console.log(greet('world'));
}

main();
