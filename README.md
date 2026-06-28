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

- `npm run serve`: start the Hugo development server on port 1313.
- `npm run lhci`: run Lighthouse CI with the configured Chrome executable.
- `npm run check:links`: check internal links against the local Hugo server.

## License

2025-2026 (c) Go Ray / @ray34g

Licensed under the MIT License. See LICENSE in the project root for license information.
