#script de deploiement des services


Write-Host "=== Deploiement Des Services De Monitoring (Docker Desktop) ===" -ForegroundColor Cyan

# Verifier le contexte
$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "Erreur: Veuillez basculer vers le contexte docker-desktop" -ForegroundColor Red
    Write-Host "Commande: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}


Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Appliquer les fichiers YAML
Write-Host "1. Deploiement de Grafana" -ForegroundColor Yellow
kubectl apply -f grafana-deployment.yaml

Write-Host "2. Deploiement de Prometheus" -ForegroundColor Yellow
kubectl apply -f prometheus-deployment.yaml

Write-Host "3. Configuration de Prometheus" -ForegroundColor Yellow
kubectl apply -f prometheus-config.yaml

Write-Host "4. Attente du demarrage des pods" -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "5. etat du cluster:" -ForegroundColor Green
kubectl get all

Write-Host "=== Deploiement termine ===" -ForegroundColor Cyan
Write-Host "Lien vers Grafana:" -ForegroundColor Green
Write-Host "   http://localhost:30300" -ForegroundColor Cyan
Write-Host "Lien vers Prometheus:" -ForegroundColor Green
Write-Host "   http://localhost:30090" -ForegroundColor Cyan
