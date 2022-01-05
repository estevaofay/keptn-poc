#!/bin/bash

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install istioctl
curl -L https://istio.io/downloadIstio | sh -

# Install keptn CLI
curl -sL https://get.keptn.sh | KEPTN_VERSION=0.11.4 bash

# Install keptn in cluster
keptn install --endpoint-service-type=ClusterIP --use-case=continuous-delivery

# Configure Istio ingress
curl -s https://raw.githubusercontent.com/keptn/examples/0.11.0/istio-configuration/configure-istio.sh | bash

# Set env vars

KEPTN_ENDPOINT=http://$(kubectl -n keptn get ingress api-keptn-ingress -ojsonpath='{.spec.rules[0].host}')/api && \
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -ojsonpath='{.data.keptn-api-token}' | base64 --decode) && \
KEPTN_BRIDGE_URL=http://$(kubectl -n keptn get ingress api-keptn-ingress -ojsonpath='{.spec.rules[0].host}')/bridge

echo [INFO] KEPTN_ENDPOINT..................: "${KEPTN_ENDPOINT}" && \
echo [INFO] KEPTN_API_TOKEN.................: "${KEPTN_API_TOKEN}" && \
echo [INFO] KEPTN_BRIDGE_URL................: "${KEPTN_BRIDGE_URL}"

keptn auth --endpoint="${KEPTN_ENDPOINT}" --api-token="${KEPTN_API_TOKEN}"

# Download Sample microservices

git clone --branch 0.11.0 https://github.com/keptn/examples.git --single-branch

cd examples/onboarding-carts

# Create Keptn Project

keptn create project sockshop --shipyard=./shipyard.yaml

# Get Keptn Credentials

KEPTN_USERNAME=$(kubectl get secret -n keptn bridge-credentials -o jsonpath="{.data.BASIC_AUTH_USERNAME}" | base64 --decode) && \
KEPTN_PASSWORD=$(kubectl get secret -n keptn bridge-credentials -o jsonpath="{.data.BASIC_AUTH_PASSWORD}" | base64 --decode)

echo [INFO] KEPTN_USERNAME...................: "${KEPTN_USERNAME}" && \
echo [INFO] KEPTN_PASSWORD...................: "${KEPTN_PASSWORD}"

# Create Keptn Service

keptn create service carts --project=sockshop
keptn add-resource --project=sockshop --service=carts --all-stages --resource=./carts.tgz --resourceUri=helm/carts.tgz

# Add funcional & performance tests

keptn add-resource --project=sockshop --stage=dev --service=carts --resource=jmeter/basiccheck.jmx --resourceUri=jmeter/basiccheck.jmx
keptn add-resource --project=sockshop --stage=staging --service=carts --resource=jmeter/load.jmx --resourceUri=jmeter/load.jmx

# Add carts-db

keptn create service carts-db --project=sockshop
keptn add-resource --project=sockshop --service=carts-db --all-stages --resource=./carts-db.tgz --resourceUri=helm/carts-db.tgz

# Deploy carts-db and carts-service

keptn trigger delivery --project=sockshop --service=carts-db --image=docker.io/mongo --tag=4.2.2 --sequence=delivery-direct
keptn trigger delivery --project=sockshop --service=carts --image=docker.io/keptnexamples/carts --tag=0.13.1

# Change directories and execute load generation

cd ../load-generation/cartsloadgen
kubectl apply -f deploy/cartsloadgen-base.yaml 

# Install Prometheus Monitoring

kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus --namespace monitoring --wait

helm install -n keptn prometheus-service https://github.com/keptn-contrib/prometheus-service/releases/download/0.7.2/prometheus-service-0.7.2.tgz --wait
kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/prometheus-service/0.7.2/deploy/role.yaml -n monitoring

# Configure Prometheus Monitoring for the Keptn Project

keptn configure monitoring prometheus --project=sockshop --service=carts

# Add Prometheus SLI to project

keptn add-resource --project=sockshop --stage=staging --service=carts --resource=sli-config-prometheus-bg.yaml --resourceUri=prometheus/sli.yaml

# Add the corresponding SLO file

keptn add-resource --project=sockshop --stage=staging --service=carts --resource=slo-quality-gates.yaml --resourceUri=slo.yaml

# Get the URLS

echo http://carts.sockshop-dev.$(kubectl -n keptn get ingress api-keptn-ingress -ojsonpath='{.spec.rules[0].host}')
echo http://carts.sockshop-staging.$(kubectl -n keptn get ingress api-keptn-ingress -ojsonpath='{.spec.rules[0].host}')
echo http://carts.sockshop-production.$(kubectl -n keptn get ingress api-keptn-ingress -ojsonpath='{.spec.rules[0].host}')

# Deploy slowbuild to test quality gates

keptn trigger delivery --project=sockshop --service=carts --image=docker.io/keptnexamples/carts --tag=0.13.2

# Deploy a regular carts version

keptn trigger delivery --project=sockshop --service=carts --image=docker.io/keptnexamples/carts --tag=0.13.3
