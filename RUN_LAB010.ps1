# RUN_LAB010.ps1 — Initial setup script for Lab 010
# Run this ONCE to seed the cluster with v1 images and initial deployments.
# Prerequisites: EKS cluster created (c7i-flex.large nodes), ECR repos created, namespaces created.

$ACCOUNT_ID = "379604374648"
$REGION     = "us-east-1"
$CLUSTER    = "cicd-lab"

Write-Host "==> Account: $ACCOUNT_ID  Region: $REGION" -ForegroundColor Cyan

# ---------- ECR Login ----------
Write-Host "`n==> Logging in to ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $REGION |
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# ---------- Build & Push v1 ----------
Write-Host "`n==> Building backend image..." -ForegroundColor Cyan
docker build -t "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-backend:v1" ./app

Write-Host "`n==> Building frontend image..." -ForegroundColor Cyan
docker build -t "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-frontend:v1" ./app/frontend

Write-Host "`n==> Pushing images..." -ForegroundColor Cyan
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-backend:v1"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-frontend:v1"

# ---------- Update kubeconfig ----------
Write-Host "`n==> Updating kubeconfig..." -ForegroundColor Cyan
aws eks update-kubeconfig --name $CLUSTER --region $REGION

# ---------- Deploy to DEV ----------
Write-Host "`n==> Deploying to dev namespace..." -ForegroundColor Cyan
kubectl -n dev apply -f manifests/
kubectl -n dev set image deployment/backend  backend="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-backend:v1"
kubectl -n dev set image deployment/frontend frontend="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-frontend:v1"

# ---------- Deploy to PROD ----------
Write-Host "`n==> Deploying to prod namespace..." -ForegroundColor Cyan
kubectl -n prod apply -f manifests/
kubectl -n prod set image deployment/backend  backend="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-backend:v1"
kubectl -n prod set image deployment/frontend frontend="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/k8s-frontend:v1"

# ---------- Wait for rollouts ----------
Write-Host "`n==> Waiting for rollouts..." -ForegroundColor Cyan
kubectl -n dev  rollout status deployment/backend  --timeout=120s
kubectl -n dev  rollout status deployment/frontend --timeout=120s
kubectl -n prod rollout status deployment/backend  --timeout=120s
kubectl -n prod rollout status deployment/frontend --timeout=120s

Write-Host "`n==> Done! Pods:" -ForegroundColor Green
kubectl get pods -n dev
kubectl get pods -n prod
