# hyve-sample-repo

A working example of a [hyve](https://github.com/cbridges1/hyve) state repository — clone it, point `hyve` at it, and explore every piece (modules, templates, workflows, clusters, `hyve.yaml`) without needing any cloud credentials.

Full documentation lives in [hyve-docs](https://github.com/cbridges1/hyve-docs).

## Why no cloud credentials?

`modules/demo-cluster` is a fully local, fake "cloud provider" module — its `create`/`delete`/`status`/`scale` operations just track state in a file (`.state/`, gitignored) instead of calling a real cloud API. It exists purely so this whole repository can be reconciled end-to-end offline, safely, as many times as you like. Everything else in this repo (templates, workflows, cluster definitions, `hyve.lock`) is exactly what a real module-backed repo looks like — swap `modules/demo-cluster` for a real module (e.g. `github.com/hyve-modules/aws-eks`) and the rest of the structure doesn't change.

## Structure

```
.
├── hyve.yaml                       # reconcile + server config
├── hyve.lock                       # locked module versions (auto-managed)
├── modules/demo-cluster/           # the fake local "cloud provider" module
├── templates/demo-template.yaml    # reusable cluster pattern using that module
├── workflows/
│   ├── setup-demo.yaml             # runs automatically on cluster create (see template's onCreate)
│   ├── cleanup-demo.yaml           # runs automatically on cluster delete (see template's onDelete)
│   └── hello-world.yaml            # standalone — run directly, demonstrates spec.inputs
└── clusters/demo-cluster-01.yaml   # a cluster created from demo-template
```

## Try it

Clone this repo and register it with hyve (or use `--path` directly):

```bash
git clone https://github.com/cbridges1/hyve-sample-repo.git
cd hyve-sample-repo
```

**Reconcile** — since `clusters/demo-cluster-01.yaml` already exists, this just confirms it's up to date. Delete the file (or set `spec.delete: true` via `hyve cluster delete demo-cluster-01`) and re-run to see the full teardown lifecycle, including the `cleanup-demo` workflow.

```bash
hyve reconcile --path .
```

**Create a second cluster from the same template:**

```bash
hyve cluster create demo-cluster-02 --template demo-template --region local-2 --set node_count=5
hyve reconcile --path .
```

**Run the standalone workflow directly:**

```bash
hyve workflow run hello-world --set NAME=you --path .
```

**Explore the REST API** (see the Server Mode guide in [hyve-docs](https://github.com/cbridges1/hyve-docs)):

```bash
hyve serve --path .
curl http://localhost:8080/clusters
curl http://localhost:8080/templates
```

**Poke around with the TUI instead of memorizing flags:**

```bash
hyve tui
```

## Modifying this repo

Every write here (`hyve template create`, `hyve cluster create`, `hyve module add`, etc.) commits and pushes automatically — that's normal hyve behavior, not specific to this repo. If you're using this as a personal scratch space, fork it first.
