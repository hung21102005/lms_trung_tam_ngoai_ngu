/* Run destructive E2E fixtures only in a new, disposable PostgreSQL database. */
require('dotenv').config();
const { randomUUID } = require('node:crypto');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { PrismaClient } = require('@prisma/client');

async function main() {
  const source = process.env.DATABASE_URL;
  if (!source) throw new Error('DATABASE_URL is required');
  const rootUrl = new URL(source);
  const name = `lms_codex_e2e_${randomUUID().replaceAll('-', '').slice(0, 12)}`;
  if (!/^lms_codex_e2e_[a-z0-9]+$/.test(name)) throw new Error('Unsafe test database name');
  const testUrl = new URL(source);
  testUrl.pathname = `/${name}`;
  rootUrl.pathname = '/postgres';
  const admin = new PrismaClient({ datasources: { db: { url: rootUrl.href } } });
  await admin.$connect();
  let created = false;
  try {
    await admin.$executeRawUnsafe(`CREATE DATABASE "${name}"`);
    created = true;
    const env = { ...process.env, DATABASE_URL: testUrl.href };
    const run = (script, args) => {
      const result = spawnSync(process.execPath, [path.join(__dirname, '..', 'node_modules', script), ...args], {
        cwd: path.join(__dirname, '..'), env, stdio: 'inherit',
      });
      if (result.error) throw result.error;
      if (result.status !== 0) throw new Error(`${script} exited with code ${result.status}`);
    };
    run(path.join('prisma', 'build', 'index.js'), ['migrate', 'deploy']);
    run(path.join('vitest', 'vitest.mjs'), ['run', '--config', './vitest.config.e2e.ts',
      'test/admissions-workflow.e2e-spec.ts']);
  } finally {
    if (created) await admin.$executeRawUnsafe(`DROP DATABASE "${name}" WITH (FORCE)`);
    await admin.$disconnect();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
