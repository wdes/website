# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

- Public website for **Wdes SAS** (https://wdes.fr).
- Static site built with **Hugo extended** (currently `0.160.1`, pinned in `Makefile`).
- Single-binary build, no Node/npm. SCSS is compiled by Hugo (`css.Sass`).
- Deployed to **GitHub Pages** on the `gh-pages` branch via the workflow at
  `.github/workflows/publish.yml` whenever `main` is updated.

## Layout

```
.
├── Makefile                # docker-based wrappers around Hugo
├── .github/workflows/      # publish workflow (gh-pages)
└── wdes.fr/                # the Hugo site (root for Hugo commands)
    ├── config.toml
    ├── archetypes/
    ├── assets/             # SCSS, JS, vendor SCSS bundled & fingerprinted by Hugo
    ├── content/            # _index.html (home), legal.{fr,en}.html, app-privacy-policy.fr.html
    ├── i18n/               # fr.toml, en.toml — all UI strings live here
    ├── layouts/_default/   # index.html (home), legal.html, app-privacy-policy.html
    ├── static/             # served as-is (favicon, robots.txt, /static/assets/{img,logo})
    └── public/             # build output (gitignored)
```

## Multilingual model

- `defaultContentLanguage = "fr"`, `defaultContentLanguageInSubdir = true`.
- Both languages live under `/fr/` and `/en/`.
- Root `/` is served as a meta-refresh redirect to `/fr/` (Hugo-generated alias).
- Translations: `*.fr.html` / `*.en.html` content files; `_index.html` (no
  language code) is shared by both languages.
- All user-visible strings come from `i18n/{en,fr}.toml` via `{{ i18n "key" }}`.
  When you add a string, add it to **both** files.

## URL conventions (important)

- The site uses **pretty URLs** (`/fr/`, `/fr/legal/`, …). Do **not** re-enable
  `uglyURLs = true` in `config.toml` — see "Known traps" below.
- Internal links must be language-aware. Use `relLangURL` instead of hardcoded
  paths:
  ```html
  <a href="{{ "/" | relLangURL }}">…</a>
  <a href="{{ "/legal/" | relLangURL }}">…</a>
  ```
  Avoid `{{ .Site.BaseURL }}{{ .Site.Language.Lang }}/legal.html` — it hardcodes
  both language and the `.html` suffix.

## Known traps

- **`uglyURLs = true` + `defaultContentLanguageInSubdir = true` causes an
  infinite redirect loop on the FR home page.** Hugo generates two aliases for
  the default-language home, and the second one is written to the same path as
  the rendered page (`/fr/index.html`), overwriting the real content with a
  meta-refresh that points back to itself. Keep pretty URLs.
- `disableKinds = ["taxonomy", "taxonomyTerm"]` triggers a deprecation warning
  (`taxonomyterm` should be `taxonomy`). Harmless today; clean up if touching
  the config.
- `hreflang` in the FR `sitemap.xml` lists both alternates as `hreflang="en"`
  (the second should be `hreflang="fr"`). This comes from Hugo's default
  sitemap template; would require a custom `layouts/sitemap.xml` to fix.

## Build & run

**Always use `make` — never call `docker run` directly.** The Hugo version is
pinned in the `Makefile` and all volume mounts / port bindings are configured
there. Running Docker by hand risks using the wrong image, wrong working
directory, or wrong flags.

```sh
make serve          # hugo serve on http://localhost:8111  (binds 0.0.0.0)
make build          # writes wdes.fr/public/
make version        # print Hugo version
make fix-perms      # chmod public/ after a containerized build (777/666)
```

**`make serve` and `make build` share the same Docker container name (`wdes.fr`).**
You cannot run both at the same time. When `make serve` is running, do NOT stop
it to run `make build` — the dev server watches files and rebuilds automatically
on every change. Only use `make build` when no dev server is running (e.g. in CI
or for a final check).

The CI workflow runs `make build`, then copies `wdes.fr/public/*` onto the
`gh-pages` branch with a `CNAME` (`wdes.fr`) and `.nojekyll`. Pushes to
`gh-pages` are signed (GPG key from secrets).

## When editing templates

- `layouts/_default/index.html` is the home page. It embeds Bootstrap, AOS,
  Material Design Icons and font-mfizz, all compiled from `assets/vendor/**`
  via `css.Sass | minify | fingerprint "sha512"` and emitted with SRI hashes.
- The `<!--sse-->…<!--/sse-->` fences mark blocks that are **stripped from
  search-engine indexing** by some crawlers. Keep contact info and personal
  data inside them.
- Matomo analytics tag is hardcoded in the home template (`analytics.wdes.eu`,
  `siteId=2`).

## Content authoring

- Add a page: `content/<slug>.<lang>.html` with front matter:
  ```yaml
  ---
  layout: <layout-name>
  ---
  ```
  Then add `layouts/_default/<layout-name>.html`.
- Home page front matter is in `content/_index.html` (`layout: index`).
- New translation strings → both `i18n/en.toml` and `i18n/fr.toml`.

## Things not to do

- Don't commit `wdes.fr/public/` (gitignored). The `gh-pages` branch is
  managed by CI; never push to it manually.
- **Never run `docker run` directly** — always use `make build`, `make serve`,
  etc. The Makefile pins the correct Hugo image, volume mounts, and flags.
  Running Docker by hand risks version mismatches and wrong build output.
- Don't use `--no-verify` or skip the GPG signing on `gh-pages` (CI does it
  with secrets; local devs should not push there).
- Don't reintroduce `uglyURLs = true` (see "Known traps").
