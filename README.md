# typescript-template

A TypeScript monorepo template: Bun 1.4.3 workspaces, tsdown builds, oxlint,
oxfmt, knip, jscpd, and a mise-pinned toolchain.

## Getting started

Create a repository from this template. With [mise](https://mise.jdx.dev)
installed:

```sh
mise trust
mise install --locked
bun install
bun run setup      # prompts for your package scope, e.g. @myscope
bun install        # relink workspace packages under the new scope
bun run check
bun run test
```

`setup` replaces the `@template` scope across every manifest and source file. It
does not rewrite `bun.lock` or the links already in `node_modules`, so `check`
and `test` cannot resolve the renamed packages until `bun install` runs again.
It does not touch the root `package.json` `name` or this README — update those by
hand, and replace or delete `LICENSE`, which covers the template rather than
whatever you build from it.

## Scripts

| Command                           | Does                                         |
| --------------------------------- | -------------------------------------------- |
| `bun install`                     | install dependencies from `bun.lock`         |
| `bun run check`                   | typecheck, lint, and format check            |
| `bun run test`                    | unit tests with `bun test`                   |
| `bun run build`                   | build every package with tsdown              |
| `bun run typecheck`               | `bun --check -b` across all projects         |
| `bun run lint` / `lint:fix`       | oxlint                                       |
| `bun run format` / `format:check` | oxfmt                                        |
| `bun run knip`                    | find unused files, exports, and dependencies |
| `bun run jscpd`                   | copy-paste detection                         |
| `bun run changeset`               | record a release note                        |

## Layout

```
apps/       private applications
packages/   publishable libraries
```

Packages build with tsdown into `dist/`, unbundled, as ESM and CJS with matching
declarations. `bun check` follows project references and leaves `dist/` to tsdown.

`isolatedDeclarations` is on, so exported symbols need explicit type
annotations. That is what lets tsdown generate declarations through oxc rather
than the TypeScript compiler.

## Adding a package

Copy a directory under `packages/`, then:

1. Keep the `<scope>/source` condition first in its `exports`, pointing at
   `./src/index.ts`. Typechecking resolves sibling packages from source through
   that condition, so `check` works before anything is built. Bun does not read
   `customConditions` from `tsconfig` at runtime, so `test` and `start` pass the
   same condition with `--conditions`.
2. Add it to `references` in the root `tsconfig.json`, and in the `tsconfig.json`
   of any package that imports it.

There is no central path map to update.

## Requirements

Bun 1.4.3 is the package manager, runtime, test runner, and type checker. The
pin lives in `mise.toml` and `engines.bun`. The lockfile is `bun.lock`.
Installs use a hoisted `node_modules` tree.

`mise.toml` and `mise.lock` pin Bun along with Tilt, lefthook, jq, ripgrep, and
uutils coreutils, with a checksum for each platform's download. CI installs the
same lockfile through `jdx/mise-action`. Activate mise in your shell, prefix
commands with `mise exec --`, or review `.envrc` and run `direnv allow`; the
direnv integration also loads the optional `.env`, `.env.local`, and
`.envrc.private` files. On Linux, mise sets
`PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`.

The weekly dependency workflow bumps the mise pins and `mise.lock` except Bun;
change Bun in `mise.toml`, `engines.bun`, and `@types/bun` together, then run
`mise lock`.
