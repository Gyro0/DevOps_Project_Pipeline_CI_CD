Write-Host "=== Deploiement Des Services De Monitoring ===" -ForegroundColor Cyan

$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "ERREUR: Contexte incorrect. Basculement vers docker-desktop..." -ForegroundColor Red
    kubectl config use-context docker-desktop
}

Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Deploy Prometheus
Write-Host "1. Deploiement de Prometheus" -ForegroundColor Yellow
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml

# Deploy Grafana with provisioning
Write-Host "2. Deploiement de Grafana avec provisioning" -ForegroundColor Yellow
kubectl apply -f grafana-provisioning.yaml
kubectl apply -f grafana-dashboard.yaml
kubectl apply -f grafana-deployment.yaml

Write-Host "3. Attente du demarrage..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=180s
kubectl wait --for=condition=ready pod -l app=grafana --timeout=180s

Write-Host "=== Deploiement termine ===" -ForegroundColor Green
Write-Host "Prometheus: http://localhost:30090" -ForegroundColor Cyan
Write-Host "Grafana: http://localhost:30300 (admin/admin)" -ForegroundColor Cyan
Write-Host "Dashboard 'YWTI Application Monitoring' disponible!" -ForegroundColor Green