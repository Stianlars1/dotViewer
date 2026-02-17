# File Type Expansion Research (2026-02-13)

Baseline from repo (`dotViewer/Shared/DefaultFileTypes.json`):
- Existing extensions: 582
- Existing filenames: 295

New-only candidates after exclusion:
- New extensions: 1069
- New exact filenames: 418
- New dotfiles (filename starts with `.`): 83
- New no-extension filenames: 113
- Role-priority candidates: 224

Primary external sources:
- GitHub Linguist: https://github.com/github-linguist/linguist/blob/main/lib/linguist/languages.yml
- Next.js config: https://nextjs.org/docs/app/api-reference/config/next-config-js
- Vite config: https://vite.dev/config/
- Astro config: https://docs.astro.build/ar/reference/configuration-reference/
- SvelteKit config: https://svelte.dev/docs/kit/configuration
- Nuxt config: https://nuxt.com/docs/guide/directory-structure/nuxt-config
- AWS SAM config/template: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-config.html
- AWS CDK app config: https://docs.aws.amazon.com/cdk/v2/guide/configure-cdk.html
- Terraform files: https://developer.hashicorp.com/terraform/language/files
- Terraform variable files (`.tfvars`, `.tfvars.json`): https://developer.hashicorp.com/terraform/language/parameterize
- Kubernetes Kustomize (`kustomization.yaml`): https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- Helm chart files (`Chart.yaml`, `values.yaml`): https://helm.sh/docs/topics/charts/
- Pulumi project/stack files: https://www.pulumi.com/docs/iac/concepts/projects/project-file/
- Docker Compose file names (`compose.yaml`, `docker-compose.yml`): https://docs.docker.com/compose/intro/compose-application-model/
- pnpm workspace file: https://pnpm.io/pnpm-workspace_yaml
- Nx config: https://nx.dev/reference/nx-json
- Turborepo config: https://turborepo.com/docs/reference/configuration
- Ruff config: https://docs.astral.sh/ruff/configuration/
- Jupyter notebook config: https://jupyter-notebook.readthedocs.io/en/stable/config.html
- DVC file layout: https://dvc.org/doc/user-guide/project-structure/dvcyaml-files

Notes:
- This output intentionally excludes anything already in your current registry.
- Quick Look still cannot route truly unknown dynamic UTIs (`dyn.*`) without explicit declarations.
