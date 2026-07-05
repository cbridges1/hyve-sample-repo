# hyve-sample-repo

A working example of a [hyve](https://github.com/cbridges1/hyve) state repository — clone it, point `hyve` at it, and explore every piece (modules, templates, workflows, clusters, `hyve.yaml`) without needing any cloud credentials.

Full documentation lives in [hyve-docs](https://github.com/cbridges1/hyve-docs).

## Why no cloud credentials?

This repo ships three fully local, fake "cloud provider" modules — `demo-civo`, `demo-aws-eks`, and `demo-gke`. Each mirrors the params a real module for that provider would expose (region/zone, node size, instance type, etc.), but every operation just tracks state in a file (`.state/`, gitignored) instead of calling a real cloud API. They exist purely so this whole repository can be reconciled end-to-end offline, safely, as many times as you like. Everything else in this repo (templates, workflows, cluster definitions, `hyve.lock`) is exactly what a real module-backed repo looks like — swap any of these for a real module (e.g. `github.com/hyve-modules/aws-eks`) and the rest of the structure doesn't change.

### Two ways to write a module: shell scripts or YAML

hyve modules can implement each operation (`create`, `delete`, `status`, `scale`, `auth`) as either a `.sh` script or a `<op>.yaml` file — hyve looks for the YAML file first, then falls back to a shell script. All three modules in this repo use the **YAML** style to demonstrate it:

- `create.yaml` / `delete.yaml` / `status.yaml` / `scale.yaml` are `kind: Workflow` documents — the same job/step shape used by `workflows/*.yaml` — whose `run:` scripts do the actual work.
- `auth.yaml` is a `kind: ClusterAuth` document describing how a real module would produce a kubeconfig; here it just prints an explanatory message since there's no real API server to authenticate into.

Neither style is "more correct" — pick whichever fits a given provider's tooling. A module can even mix both (e.g. `create.sh` alongside `status.yaml`).

## Structure

```
.
├── hyve.yaml                             # reconcile + server config
├── hyve.lock                             # locked module versions (auto-managed)
├── modules/
│   ├── demo-civo/                        # fake Civo-flavored module (region, node_size, node_count)
│   ├── demo-aws-eks/                     # fake AWS EKS-flavored module (vpc_id, node_role_name, instance_type)
│   └── demo-gke/                         # fake GKE-flavored module (project, zone, machine_type)
│       ├── module.yaml                   # manifest: params + metadata
│       ├── create.yaml / delete.yaml     # kind: Workflow — provisioning lifecycle
│       ├── status.yaml / scale.yaml      # kind: Workflow — status + resize
│       └── auth.yaml                     # kind: ClusterAuth — kubeconfig auth method
├── templates/
│   ├── demo-civo-template.yaml           # uses modules/demo-civo
│   ├── demo-aws-template.yaml            # uses modules/demo-aws-eks
│   └── demo-gcp-template.yaml            # uses modules/demo-gke
├── workflows/
│   ├── setup-demo.yaml                   # runs automatically on cluster create (see each template's onCreate)
│   ├── cleanup-demo.yaml                 # runs automatically on cluster delete (see each template's onDelete)
│   └── hello-world.yaml                  # standalone — run directly, demonstrates spec.inputs
└── clusters/                             # one cluster created from each template
    ├── demo-civo-01.yaml
    ├── demo-aws-01.yaml
    └── demo-gcp-01.yaml
```

## Try it

Clone this repo and register it with hyve (or use `--path` directly):

```bash
git clone https://github.com/cbridges1/hyve-sample-repo.git
cd hyve-sample-repo
```

**Reconcile** — since the three `clusters/*.yaml` files already exist, this just confirms they're up to date across all three fake providers. Delete a file (or run `hyve cluster delete <name>`) and re-run to see the full teardown lifecycle, including the `cleanup-demo` workflow.

```bash
hyve reconcile --path .
```

**Create another cluster from any template:**

```bash
hyve cluster create demo-civo-02 --template demo-civo-template --region NYC2 --set node_count=5
hyve cluster create demo-aws-02 --template demo-aws-template --set instance_type=t3.large
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
curl http://localhost:8080/modules
```

**Poke around with the TUI instead of memorizing flags:**

```bash
hyve tui
```

## Modifying this repo

Every write here (`hyve template create`, `hyve cluster create`, `hyve module add`, etc.) commits and pushes automatically — that's normal hyve behavior, not specific to this repo. If you're using this as a personal scratch space, fork it first.
