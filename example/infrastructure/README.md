# Infrastructure

A small template deployment demonstrating directory and multiple-output hashing.

- `templates` packages the YAML templates as `templates.tar` using
  [rules_pkg](https://github.com/bazelbuild/rules_pkg).
- `deployment` produces four artifacts: `templates.out/` containing the YAML
  files, `templates.link` pointing to that directory, an empty `pending/`
  directory for pending deployments, and an empty `deployment.log` file.

Each artifact gets its own adjacent `.paq`. `templates.out.paq` covers the whole
directory; its children do not get individual hash files. `templates.link.paq`
contains the same hash because paq follows the directory link.
