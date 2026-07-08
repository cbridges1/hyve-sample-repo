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
│   ├── k3d-template.yaml                 # uses modules/k3d
│   ├── civo-template.yaml                # uses modules/civo
│   ├── aws-eks-template.yaml             # uses modules/aws-eks
│   └── gke-template.yaml                 # uses modules/gke
├── workflows/
│   ├── setup-demo.yaml                   # runs automatically on cluster create (see each template's onCreate)
│   ├── cleanup-demo.yaml                 # runs automatically on cluster delete (see each template's onDelete)
│   └── hello-world.yaml                  # standalone — run directly, demonstrates spec.inputs
└── clusters/
    └── local-k3d-01.yaml                 # ready to reconcile — no credentials required
```

## Try it

Clone this repo and register it with hyve (or use `--path` directly). You'll need [Docker](https://docker.com) and [k3d](https://k3d.io) installed for the credential-free path:

```bash
git clone https://github.com/cbridges1/hyve-sample-repo.git
cd hyve-sample-repo
```

**Reconcile** — `clusters/local-k3d-01.yaml` isn't pre-created; this actually spins up a real k3d cluster (containers, via Docker) the first time you run it:

```bash
hyve reconcile --path .
hyve cluster auth local-k3d-01 --path .
kubectl get nodes
```

Delete it (or run `hyve cluster delete local-k3d-01`) and reconcile again to see the full teardown lifecycle, including the `cleanup-demo` workflow — the k3d containers are genuinely removed.

**Create another local cluster from the template:**

```bash
hyve cluster create local-k3d-02 --template k3d-template --set agent_count=2
hyve reconcile --path .
```

**Use a real cloud provider** — fill in the placeholder params in the template first (subnets/IAM roles for EKS, project for GKE, or just set `CIVO_TOKEN` for Civo), then:

```bash
hyve cluster create my-civo-cluster --template civo-template --region NYC2
hyve reconcile --path .
```

**Run the standalone workflow directly:**

```bash
hyve workflow run hello-world --set NAME=you --path .
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
