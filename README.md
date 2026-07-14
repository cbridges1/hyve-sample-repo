# hyve-sample-repo

A working example of a [hyve](https://github.com/cbridges1/hyve) state repository — clone it, point `hyve` at it, and explore every piece (modules, templates, workflows, clusters, `hyve.yaml`).

Full documentation lives in [hyve-website](https://github.com/cbridges1/hyve-website).

## Four real modules, one needs no credentials

This repo ships four modules, and every one of them shells out to the **real** provider CLI — no fake state files, no simulated APIs:

| Module | Provider | Credentials needed |
|---|---|---|
| `modules/k3d` | Local k3s-in-Docker via the `k3d` CLI | **None** — just Docker |
| `modules/civo` | Civo Kubernetes | `CIVO_TOKEN` (or `civo apikey save`) |
| `modules/aws-eks` | Amazon EKS | AWS credentials + an existing VPC/subnets/IAM roles |
| `modules/gke` | Google Kubernetes Engine | `gcloud auth login` + a GCP project |

**Start with `k3d`** — it's the only one that works out of the box with zero setup, and it's genuinely real: `hyve reconcile` will actually create Docker containers running k3s on your machine, not pretend to. The civo/aws-eks/gke modules are complete, working reference implementations you can point at your own accounts once you have credentials — fill in the placeholder values in their templates (`subnet_ids`, `eks_role_arn`, `project`, etc.) first.

### Two ways to write a module: shell scripts or YAML

hyve modules can implement each operation (`create`, `delete`, `status`, `scale`, `auth`) as either a `.sh` script or a `<op>.yaml` file — hyve looks for the YAML file first, then falls back to a shell script. All four modules in this repo use the **YAML** style to demonstrate it:

- `create.yaml` / `delete.yaml` / `status.yaml` / `scale.yaml` are `kind: Workflow` documents — the same job/step shape used by `workflows/*.yaml` — whose `script:` steps shell out to the real CLI (`civo`, `aws`, `gcloud`, or `k3d`) and parse its JSON output with `jq`.
- `auth.yaml` is a `kind: ClusterAuth` document that runs the provider's real kubeconfig command (`civo kubernetes config --save`, `aws eks update-kubeconfig`, `gcloud container clusters get-credentials`, `k3d kubeconfig merge`).

Neither style is "more correct" — pick whichever fits a given provider's tooling. A module can even mix both (e.g. `create.sh` alongside `status.yaml`).

## Structure

```
.
├── hyve.yaml                             # reconcile + server config
├── hyve.lock                             # locked module versions (auto-managed)
├── modules/
│   ├── k3d/                              # local k3s-in-Docker — no credentials needed
│   ├── civo/                             # real Civo Kubernetes (region, node_size, node_count)
│   ├── aws-eks/                          # real Amazon EKS (subnet_ids, eks_role_arn, node_role_arn)
│   └── gke/                              # real GKE (project, zone, machine_type)
│       ├── module.yaml                   # manifest: params + requirements (tools/env)
│       ├── create.yaml / delete.yaml     # kind: Workflow — provisioning lifecycle
│       ├── status.yaml / scale.yaml      # kind: Workflow — status + resize
│       └── auth.yaml                     # kind: ClusterAuth — kubeconfig auth method
├── templates/
│   ├── k3d-template.yaml                 # uses modules/k3d + a source: resource (see below)
│   ├── civo-template.yaml                # uses modules/civo + helm:/secret: resources (see below)
│   ├── aws-eks-template.yaml             # uses modules/aws-eks
│   └── gke-template.yaml                 # uses modules/gke
├── resource-files/
│   └── whoami/manifest.yaml              # the raw manifest k3d-template's source: resource applies
├── workflows/
│   ├── setup-demo.yaml                   # runs automatically on cluster create (see each template's onCreate)
│   ├── cleanup-demo.yaml                 # runs automatically on cluster delete (see each template's onDelete)
│   └── hello-world.yaml                  # standalone — run directly, demonstrates spec.inputs
└── clusters/
    └── local-k3d-01.yaml                 # ready to reconcile — no credentials required
```

## `spec.resources` — Kubernetes manifests, Helm releases, and Secrets

On top of provisioning the cluster itself, Hyve can own a layer of in-cluster resources — declared once, drift-checked and re-applied on every reconcile, the same way Terraform's `kubernetes`/`helm` providers work. Full docs: [Cluster Resources](https://cbridges1.github.io/hyve-website/docs/concepts/resources).

Both non-`aws-eks`/`gke` templates demo a different kind:

- **`k3d-template.yaml`** — a plain manifest (`source: ./resource-files/whoami/manifest.yaml`), deploying [`traefik/whoami`](https://github.com/traefik/whoami), a tiny HTTP echo server. Zero extra dependencies beyond what auth already needs (`kubectl`).
- **`civo-template.yaml`** — a Helm release (`podinfo`, via `helm:`) plus a `secret:` resource rendered from your own shell environment at reconcile time, in both its forms (a bare env-var name, and the `{env, key}` mapping to rename). Needs `helm` on `PATH` in addition to `civo`/`jq`/`kubectl`. The demo secret isn't wired into podinfo — it's a standalone illustration of the feature — export `DEMO_GREETING` and `DEMO_API_KEY` (or drop them in a local `.env`, gitignored) before you reconcile, or it fails loudly naming exactly what's missing.

## Try it

Clone this repo and register it with hyve, pointing at your existing checkout with `--path` rather than having hyve clone a fresh copy into `~/.hyve/repositories`. You'll need [Docker](https://docker.com) and [k3d](https://k3d.io) installed for the credential-free path:

```bash
git clone https://github.com/cbridges1/hyve-sample-repo.git
cd hyve-sample-repo
hyve git add sample --repo-url https://github.com/cbridges1/hyve-sample-repo.git --path . --set-current
```

<sub>Only `hyve reconcile`, `hyve serve`, and `hyve open` accept a direct `--path` override for a one-off command against a repo that isn't registered — `hyve cluster`/`hyve template`/`hyve workflow` subcommands always operate on whatever's currently registered (`hyve git add ... --set-current`, or switch later with `hyve git use sample`). Register once and every command below works with no flag.</sub>

**Reconcile** — `clusters/local-k3d-01.yaml` isn't pre-created; this actually spins up a real k3d cluster (containers, via Docker) the first time you run it, and — via its `spec.resources` — deploys the `whoami` app for real too:

```bash
hyve reconcile
hyve cluster auth local-k3d-01
kubectl get nodes
kubectl get pods                        # whoami, applied by spec.resources
hyve cluster resources local-k3d-01     # declared + tracked resource state
```

Delete it (or run `hyve cluster delete local-k3d-01`) and reconcile again to see the full teardown lifecycle, including the `cleanup-demo` workflow — the k3d containers are genuinely removed.

**Create another local cluster from the template:**

```bash
hyve cluster create local-k3d-02 --template k3d-template --set agent_count=2
hyve reconcile
```

**Use a real cloud provider** — fill in the placeholder params in the template first (subnets/IAM roles for EKS, project for GKE, or just set `CIVO_TOKEN` for Civo; for `civo-template`'s `spec.resources` demo, also install `helm` and export `DEMO_GREETING`/`DEMO_API_KEY`), then:

```bash
hyve cluster create my-civo-cluster --template civo-template --region NYC2
hyve reconcile
```

**Run the standalone workflow directly:**

```bash
hyve workflow run hello-world --set NAME=you
```

**Explore the REST API** (see the Server Mode guide in [hyve-website](https://github.com/cbridges1/hyve-website)):

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
