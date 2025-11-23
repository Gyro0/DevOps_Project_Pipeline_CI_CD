# Script de déploiement Kubernetes - Étape 5
# YourWayToItaly - Docker Desktop

Write-Host "=== Déploiement sur Kubernetes (Docker Desktop) ===" -ForegroundColor Cyan

# Vérifier le contexte
$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "Erreur: Veuillez basculer vers le contexte docker-desktop" -ForegroundColor Red
    Write-Host "Commande: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}


Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Appliquer les fichiers YAML
Write-Host "`n1. Déploiement des applications..." -ForegroundColor Yellow
kubectl apply -f deployment.yaml

Write-Host "`n2. Création des services..." -ForegroundColor Yellow
kubectl apply -f service.yaml

Write-Host "`n3. Configuration de l'Ingress..." -ForegroundColor Yellow
kubectl apply -f ingress.yaml

Write-Host "`n4. Attente du démarrage des pods..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`n5. Initialisation de la base de données..." -ForegroundColor Yellow
kubectl delete job init-db 2>$null
kubectl apply -f init-db-job.yaml
kubectl wait --for=condition=complete job/init-db --timeout=60s

Write-Host "`n6. État du cluster:" -ForegroundColor Green
kubectl get all

Write-Host "`n7. Ingress:" -ForegroundColor Green
kubectl get ingress

Write-Host "`n=== Déploiement terminé ===" -ForegroundColor Cyan
Write-Host "`nPour accéder à l'application:" -ForegroundColor Green
Write-Host "1. Ajoutez cette ligne à C:\Windows\System32\drivers\etc\hosts (en tant qu'admin):" -ForegroundColor Yellow
Write-Host "   127.0.0.1    ywti.local" -ForegroundColor Cyan
Write-Host "`n2. Accédez à l'application via:" -ForegroundColor Yellow
Write-Host "   http://ywti.local/html/index.html" -ForegroundColor Cyan
Write-Host "`n   OU via NodePort directement:" -ForegroundColor Yellow
Write-Host "   http://localhost:30080/html/index.html" -ForegroundColor Cyan
