export interface RunResult {
  lastInsertRowid?: number | bigint;
  changes: number;
}

/** Async statement handle (Postgres). Same shape as the old better-sqlite3 one, but awaitable. */
export interface DbStatement {
  get(...params: unknown[]): Promise<unknown>;
  all(...params: unknown[]): Promise<unknown[]>;
  run(...params: unknown[]): Promise<RunResult>;
}

export interface Db {
  prepare(sql: string): DbStatement;
  /** Run one or more raw statements (no parameters). */
  exec(sql: string): Promise<void>;
  /**
   * Wraps fn in a transaction and returns an async callable. Queries made through
   * this Db inside fn (including from nested helpers) automatically join the
   * transaction. Nested calls become savepoints.
   */
  transaction<F extends (...args: any[]) => unknown>(
    fn: F,
  ): (...args: Parameters<F>) => Promise<Awaited<ReturnType<F>>>;
  /** SQLite leftover: accepted and ignored on Postgres. */
  pragma(source: string): unknown;
  close?(): Promise<void>;
}
