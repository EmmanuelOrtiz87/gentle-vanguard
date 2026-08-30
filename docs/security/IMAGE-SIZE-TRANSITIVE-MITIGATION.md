# image-size Transitive Vulnerability

## Findings

- `image-size` was not a direct dependency. `pnpm why image-size` showed
  `pptxgenjs@4.0.1 -> image-size@1.2.1`; `pptxgenjs` was a root `devDependency`.
- The only repository import is `skills/huashu-design/scripts/export_deck_pptx.mjs`. No application
  runtime code imports either package.
- The npm registry currently has `pptxgenjs@4.0.1` as latest and `image-size@2.0.2` as latest. npm
  audit reports the patched range as `>=2.0.3`, but that version is not published
  ([npm package](https://www.npmjs.com/package/image-size),
  [GitHub advisories](https://github.com/advisories/GHSA-w3rx-r6r6-pgpr) and
  [GHSA-5p2g-fcmc-qvqq](https://github.com/advisories/GHSA-5p2g-fcmc-qvqq)).
- `probe-image-size` is a remote/streaming probe with a different result and loading API.
  `image-dimensions` is also a different API and module format. Neither is a demonstrated drop-in
  replacement for `pptxgenjs`'s internal `image-size` contract, so neither was added.
- The official `pptxgenjs` registry package is [`4.0.1`](https://www.npmjs.com/package/pptxgenjs),
  and its manifest still requires `image-size`. The upstream `image-size` repository contains the
  zero-size-box loop fix on [`main`](https://github.com/image-size/image-size), but its package
  metadata remains `2.0.2` and the repository does not publish the `dist` directory required by its
  package exports. A Git fork dependency would therefore be an unverified supply-chain/build choice.

## Mitigation

`pptxgenjs` was removed from the root `devDependencies` and lockfile. The optional PPTX exporter
remains isolated under `skills/huashu-design`, whose standalone package manifest documents its own
dependencies. Root installation and runtime no longer install or load the vulnerable transitive
package.

If PPTX export is needed, install and audit that skill environment separately; do not promote its
dependencies into the root runtime until `pptxgenjs` adopts the published patched `image-size`
release or a tested maintained fork is available.
