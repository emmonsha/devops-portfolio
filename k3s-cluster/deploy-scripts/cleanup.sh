#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting cleanup of deployment...${NC}"

# Delete in reverse order to respect dependencies
echo -e "\n${YELLOW}Cleaning up networking...${NC}"
kubectl delete -f ../my_k3s/networking/ingress.yaml 2>/dev/null || echo "Ingress not found or already deleted"

echo -e "\n${YELLOW}Cleaning up certificates...${NC}"
kubectl delete -f ../my_k3s/certificates/local-cert.yaml 2>/dev/null || echo "Certificate not found or already deleted"

echo -e "\n${YELLOW}Cleaning up services...${NC}"
services=("gateway" "report" "payment" "loyalty" "booking" "hotel" "session" "rabbitmq")
for service in "${services[@]}"; do
    kubectl delete -f "../my_k3s/services/${service}.yaml" 2>/dev/null || echo "${service} not found or already deleted"
done

echo -e "\n${YELLOW}Cleaning up database...${NC}"
kubectl delete -f ../my_k3s/database/postgresql.yaml 2>/dev/null || echo "PostgreSQL not found or already deleted"
kubectl delete -f ../my_k3s/database/postgres-pv.yaml 2>/dev/null || echo "PostgreSQL PV not found or already deleted"

echo -e "\n${YELLOW}Cleaning up base components...${NC}"
kubectl delete -f ../my_k3s/base/secrets.yaml 2>/dev/null || echo "Secrets not found or already deleted"
kubectl delete -f ../my_k3s/base/configmap.yaml 2>/dev/null || echo "ConfigMap not found or already deleted"

# Clean up any remaining resources
echo -e "\n${YELLOW}Cleaning up orphaned resources...${NC}"
kubectl delete pvc --all 2>/dev/null || echo "No PVCs to delete"
kubectl delete pv --all 2>/dev/null || echo "No PVs to delete"

echo -e "\n${GREEN}Cleanup completed!${NC}"
echo -e "\n${YELLOW}Remaining resources:${NC}"
kubectl get all