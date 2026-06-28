## Profile

**Go Ray / [@ray34g](https://twitter.com/ray34g)**

Tokyo, JAPAN

## Development

This repository uses a Hugo/Node/Chrome toolchain container for local development
and CI. The devcontainer follows the same structure as the Giving Machine
projects: a workspace service for builds and an nginx service for static preview.

```sh
npm ci
npm run build
```

Common local entry points:

- `npm run build:pages`: build the production site through the CI build script.
- `npm run build:preview`: build the preview variant to `public-preview/`.
- `npm run verify:pages`: verify generated pages, local references, and i18n keys.
- `npm run serve`: start the Hugo development server on port 1313.
- `npm run lhci`: run Lighthouse CI with the configured Chrome executable.
- `npm run check:links`: check internal links against the local Hugo server.

Build, generated-output verification, and internal link checks are blocking
quality gates in GitHub Actions. Lighthouse CI is enabled as a non-blocking
signal for ongoing performance and accessibility work.

Environment-specific Hugo entry points:

```sh
hugo server --environment development
hugo --environment preview
hugo --environment production
```

## License

2025-2026 (c) Go Ray / @ray34g

Licensed under the MIT License. See LICENSE in the project root for license information.

## Operations Docs

- `docs/operations/01-setup.md`
- `docs/operations/02-release-flow.md`
- `docs/operations/03-incident-template.md`
- `docs/operations/04-content-guidelines.md`
- `docs/theme/outline.md`
