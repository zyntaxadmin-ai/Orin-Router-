// Sequential/parallel helpers for array callbacks that became async when the
// database moved from synchronous SQLite to Postgres.

export async function asyncMap<T, R>(arr: readonly T[], fn: (item: T, index: number) => Promise<R> | R): Promise<R[]> {
  return Promise.all(arr.map(async (item, i) => (await fn(item, i))));
}

export async function asyncFilter<T>(arr: readonly T[], fn: (item: T, index: number) => Promise<unknown> | unknown): Promise<T[]> {
  const keep = await Promise.all(arr.map((item, i) => fn(item, i)));
  return arr.filter((_, i) => !!keep[i]);
}

export async function asyncSome<T>(arr: readonly T[], fn: (item: T, index: number) => Promise<unknown> | unknown): Promise<boolean> {
  for (let i = 0; i < arr.length; i++) if (await fn(arr[i], i)) return true;
  return false;
}

export async function asyncEvery<T>(arr: readonly T[], fn: (item: T, index: number) => Promise<unknown> | unknown): Promise<boolean> {
  for (let i = 0; i < arr.length; i++) if (!(await fn(arr[i], i))) return false;
  return true;
}

export async function asyncFind<T>(arr: readonly T[], fn: (item: T, index: number) => Promise<unknown> | unknown): Promise<T | undefined> {
  for (let i = 0; i < arr.length; i++) if (await fn(arr[i], i)) return arr[i];
  return undefined;
}

export async function asyncForEach<T>(arr: readonly T[], fn: (item: T, index: number) => unknown): Promise<void> {
  for (let i = 0; i < arr.length; i++) await fn(arr[i], i);
}
