#!/bin/bash

set -e

echo "Starting deployment of K3s cluster services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Wait for cluster to be ready
log_info "Checking cluster status..."
kubectl cluster-info
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# 1. Deploy base components (configmaps, secrets)
log_info "Deploying base components..."
kubectl apply -f ../my_k3s/base/configmap.yaml
kubectl apply -f ../my_k3s/base/secrets.yaml

# Wait for secrets to be applied
sleep 5

# 2. Deploy database components (PV, PVC, PostgreSQL)
log_info "Deploying database components..."
kubectl apply -f ../my_k3s/database/postgres-pv.yaml
kubectl apply -f ../my_k3s/database/postgresql.yaml

# Wait for PostgreSQL to be ready
log_info "Waiting for PostgreSQL to be ready..."
if kubectl wait --for=condition=Ready pods -l app=postgresql --timeout=300s 2>/dev/null; then
    log_info "PostgreSQL is ready"
else
    log_warn "PostgreSQL not ready yet, continuing deployment..."
fi

# 3. Deploy RabbitMQ
log_info "Deploying RabbitMQ..."
if [ -f ../my_k3s/services/rabbitmq.yaml ]; then
    kubectl apply -f ../my_k3s/services/rabbitmq.yaml
    if kubectl wait --for=condition=Ready pods -l app=rabbitmq --timeout=300s 2>/dev/null; then
        log_info "RabbitMQ is ready"
    else
        log_warn "RabbitMQ not ready yet, continuing deployment..."
    fi
else
    log_warn "RabbitMQ manifest not found, skipping..."
fi

# 4. Deploy services
log_info "Deploying services..."
services=("session" "hotel" "booking" "loyalty" "payment" "report" "gateway")
for service in "${services[@]}"; do
    if [ -f "../my_k3s/services/${service}.yaml" ]; then
        log_info "Deploying ${service} service..."
        kubectl apply -f "../my_k3s/services/${service}.yaml"
    else
        log_warn "${service}.yaml manifest not found, skipping..."
    fi
done

# Wait for services to start (with more flexible approach)
log_info "Waiting for services to be ready..."
sleep 30

# Check pod status
log_info "Checking pod status..."
kubectl get pods --field-selector=status.phase!=Succeeded

# 5. Deploy certificates
log_info "Deploying certificates..."
if [ -f ../my_k3s/certificates/local-cert.yaml ]; then
    kubectl apply -f ../my_k3s/certificates/local-cert.yaml
    if kubectl wait --for=condition=Ready certificates --all --timeout=300s 2>/dev/null; then
        log_info "Certificates are ready"
    else
        log_warn "Certificates not ready yet, continuing deployment..."
    fi
else
    log_warn "Certificate manifest not found, skipping..."
fi

# 6. Deploy networking (Ingress)
log_info "Deploying networking..."
kubectl apply -f ../my_k3s/networking/ingress.yaml

# Wait for ingress controller to be ready
log_info "Waiting for ingress controller to be ready..."
if kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s 2>/dev/null; then
    log_info "Ingress controller is ready"
else
    log_warn "Ingress controller not ready yet..."
fi

# Final status check
log_info "Checking final deployment status..."
echo -e "\n${GREEN}=== Cluster Overview ===${NC}"
kubectl get nodes

echo -e "\n${GREEN}=== Pods Status ===${NC}"
kubectl get pods -o wide

echo -e "\n${GREEN}=== Services ===${NC}"
kubectl get svc

echo -e "\n${GREEN}=== Ingress ===${NC}"
kubectl get ingress

echo -e "\n${GREEN}=== Certificates ===${NC}"
kubectl get certificates,certificaterequests

echo -e "\n${GREEN}=== Persistent Volumes ===${NC}"
kubectl get pv,pvc

log_info "Deployment completed!"
echo -e "\n${GREEN}Services deployed:${NC}"
echo "- PostgreSQL: postgresql-service:5432"
echo "- RabbitMQ: rabbitmq-service:5672"
echo "- Session Service: session-service:8080"
echo "- Hotel Service: hotel-service:8080"
echo "- Booking Service: booking-service:8080"
echo "- Loyalty Service: loyalty-service:8080"
echo "- Payment Service: payment-service:8080"
echo "- Report Service: report-service:8080"
echo "- Gateway Service: gateway-service:8080"

echo -e "\n${GREEN}Access:${NC}"
echo "- API: https://emmonsha.ru/api/v1/"
echo "- Health: https://emmonsha.ru/api/v1/health"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Check if all pods are running: kubectl get pods"
echo "2. Check certificate status: kubectl get certificates"
echo "3. Test ingress: curl -k https://emmonsha.ru/api/v1/health"