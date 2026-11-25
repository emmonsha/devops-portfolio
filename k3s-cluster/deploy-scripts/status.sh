#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Deployment Status Check ===${NC}"

echo -e "\n${GREEN}=== Nodes ===${NC}"
kubectl get nodes -o wide

echo -e "\n${GREEN}=== Pods Status ===${NC}"
kubectl get pods -A --sort-by='.metadata.creationTimestamp'

echo -e "\n${GREEN}=== Services ===${NC}"
kubectl get svc -A

echo -e "\n${GREEN}=== Ingress ===${NC}"
kubectl get ingress -A

echo -e "\n${GREEN}=== Certificates ===${NC}"
kubectl get certificates,certificaterequests -A

echo -e "\n${GREEN}=== Persistent Volumes ===${NC}"
kubectl get pv,pvc -A

echo -e "\n${GREEN}=== Recent Events ===${NC}"
kubectl get events -A --sort-by='.lastTimestamp' --field-selector type!=Normal | tail -20

echo -e "\n${GREEN}=== Application Pods Logs ===${NC}"

# Check PostgreSQL
echo -e "\n${YELLOW}--- PostgreSQL ---${NC}"
if kubectl get pods -l app=postgresql &>/dev/null; then
    kubectl logs -l app=postgresql --tail=5 || echo "No logs available"
else
    echo "PostgreSQL pod not found"
fi

# Check RabbitMQ
echo -e "\n${YELLOW}--- RabbitMQ ---${NC}"
if kubectl get pods -l app=rabbitmq &>/dev/null; then
    kubectl logs -l app=rabbitmq --tail=5 || echo "No logs available"
else
    echo "RabbitMQ pod not found"
fi

# Check microservices
services=("session" "gateway" "booking" "hotel" "loyalty" "payment" "report")
for service in "${services[@]}"; do
    echo -e "\n${YELLOW}--- ${service^} Service ---${NC}"
    if kubectl get pods -l app=$service &>/dev/null; then
        kubectl logs -l app=$service --tail=3 2>/dev/null || echo "No logs available or pod not ready"
    else
        echo "${service^} service pod not found"
    fi
done

echo -e "\n${GREEN}=== Network Policies ===${NC}"
kubectl get networkpolicies -A

echo -e "\n${GREEN}=== Resource Usage ===${NC}"
kubectl top pods -A 2>/dev/null || echo "Metrics server not available"

echo -e "\n${GREEN}Status check completed!${NC}"