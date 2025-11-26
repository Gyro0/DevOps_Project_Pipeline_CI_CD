#script de deploiement Kubernetes


Write-Host "=== Deploiement sur Kubernetes (Docker Desktop) ===" -ForegroundColor Cyan

# Verifier le contexte
$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "Erreur: Veuillez basculer vers le contexte docker-desktop" -ForegroundColor Red
    Write-Host "Commande: kubectl config use-context docker-desktop" -ForegroundColor Yellow
    exit 1
}


Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Appliquer tous les fichiers YAML
Write-Host "1. Deploiement des applications" -ForegroundColor Yellow
kubectl apply -f deployment.yaml

Write-Host "2. Creation des services" -ForegroundColor Yellow
kubectl apply -f service.yaml

Write-Host "3. Configuration de l'Ingress" -ForegroundColor Yellow
kubectl apply -f ingress.yaml

Write-Host "4. Attente du demarrage des pods" -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "5. Initialisation de la base de donnees" -ForegroundColor Yellow
kubectl delete job init-db 2>$null
kubectl apply -f init-db-job.yaml
kubectl wait --for=condition=complete job/init-db --timeout=10s

Write-Host "6. etat du cluster:" -ForegroundColor Green
kubectl get all

Write-Host "7. Ingress:" -ForegroundColor Green
kubectl get ingress

Write-Host "=== Deploiement termine ===" -ForegroundColor Cyan
Write-Host "Lien vers l'application:" -ForegroundColor Green
Write-Host "   http://ywti.local/html/index.html" -ForegroundColor Cyan
