#!/usr/bin/env bash
set -euo pipefail

# Make sure we are able to connect to a cluster
ensure_kubernetes() {
  kubectl get ns >/dev/null
}

# Use ENVSUBST to populate template files. It appends -envsub to the filename
# when applying/using the file post passing to this function, make sure to use the new filename
run_envsubst_on_file() {
  envsubst < $1 > $1-envsub
}

# Create the Docker Registry secret we will be using
# TODO: This and the create_credentials functions are doing very similar things, need to combine and do in one shot?
create_registry_secret(){
  ensure_namespace $2
  # This tests if the secret exists and if it doesnt it generates it
  # maybe a little hackish but does the trick without having to do weird bash checks
  kubectl create secret docker-registry $1 -n $2 --docker-server=${REGISTRY} --docker-username=${GITHUB_TOKEN_USER} --docker-password=${GITHUB_TOKEN} --docker-email=backstack-noop@backstack.dev --dry-run=client -o yaml | kubectl apply -f -
}

create_credentials_secret() {
  ensure_namespace crossplane-system
  kubectl apply -f - <<-EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: ${$1}
      namespace: ${$2}
    data:
      credentials: $(echo -n "${GCP_CREDENTIALS}" | base64 -w 0)
EOF
}

# Check the Providers are up and running
# TODO: figure out a good way to potentially do this as a generalized function
validate_upbound_providers() {
  for provider in {upbound-provider-{family-gcp,gcp-{cloudplatform,container,compute}}}; do
    kubectl wait providers.pkg.crossplane.io/${provider} --for='condition=healthy' --timeout=5m
  done
}

# Pass in the name defined in the manifests/crossplane/bead.yaml
validate_bead_configuration() {
  kubectl wait configuration/$1 --for='condition=healthy' --timeout=10m
}

# Make sure a namespace exists and create it if not
ensure_namespace() {
  kubectl get namespaces -o name | grep -q $1 || kubectl create namespace $1
}

# Restart a pod in a namespace
restart_pod() {
  kubectl rollout restart deployment $2 -n $1
}

install() {
  echo Hello World
}

upgrade() {
  echo World 2.0
}

uninstall() {
  echo Goodbye World
}

# Call the requested function and pass the arguments as-is
"$@"
