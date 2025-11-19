# Initialize the production environment with remote state backend

terraform -chdir=azure/envs/prod init -backend-config=azure/backend.hcl