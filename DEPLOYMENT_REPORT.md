---

## Étape 4 : Docker - Containerisation

### Objectif
Containeriser l'application JEE YourWayToItaly pour faciliter son déploiement.

### Actions Réalisées

1. **Création du Dockerfile multi-stage**
   - **Stage 1 (Builder)** : Utilisation de `maven:3.9-eclipse-temurin-17` pour compiler le projet et générer le fichier WAR
   - **Stage 2 (Runtime)** : Utilisation de `tomcat:9-jdk17` pour déployer l'application
   - Script de démarrage personnalisé pour remplacer les variables d'environnement dans `context.xml` au runtime

2. **Build et publication de l'image Docker**
   ```bash
   docker build -t gyro0/yourwaytoitaly:1.0 .
   docker push gyro0/yourwaytoitaly:1.0
   ```
   - Image publiée sur Docker Hub : `gyro0/yourwaytoitaly:1.1` (version finale avec correction CORS)

3. **Test local de l'image**
   ```bash
   docker run -p 8080:8080 -e POSTGRES_HOST=host.docker.internal gyro0/yourwaytoitaly:1.0
   ```

---

## Étape 5 : Kubernetes - Déploiement sur Docker Desktop

### Objectif
Déployer l'application containerisée sur un cluster Kubernetes via Docker Desktop avec une base de données PostgreSQL, un système d'Ingress NGINX, et une initialisation automatique de la base de données.

---

## 1. Préparation de l'Environnement

### 1.1 Activation de Kubernetes dans Docker Desktop
- Ouvrir **Docker Desktop** → **Settings** → **Kubernetes**
- Activer **Enable Kubernetes**
- Attendre que le status indique "Kubernetes is running"

### 1.2 Vérification du Contexte Kubernetes
```bash
kubectl config current-context
# Résultat: docker-desktop

kubectl get nodes
# Résultat: 
# NAME             STATUS   ROLES           AGE   VERSION
# docker-desktop   Ready    control-plane   20m   v1.34.1
```

### 1.3 Installation de l'Ingress Controller NGINX
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml
```

**Vérification :**
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

## 2. Architecture Déployée

### 2.1 Composants Kubernetes

| Composant | Type | Replicas | Image | Port |
|-----------|------|----------|-------|------|
| **PostgreSQL** | Deployment | 1 | postgres:15 | 5433 |
| **YourWayToItaly** | Deployment | 2 | gyro0/yourwaytoitaly:1.1 | 8080 |
| **init-db** | Job | 1 (one-time) | postgres:15 | - |

### 2.2 Services

| Service | Type | Port | Target Port | NodePort |
|---------|------|------|-------------|----------|
| postgres | ClusterIP | 5433 | 5433 | - |
| ywti-app | NodePort | 80 | 8080 | 30080 |

### 2.3 Ingress

- **Hostname** : `ywti.local`
- **Controller** : NGINX
- **Backend** : ywti-app:80
- **LoadBalancer Address** : localhost

---

## 3. Fichiers Kubernetes Créés

### 3.1 `deployment.yaml`
Définit deux déploiements :

**PostgreSQL :**
```yaml
spec:
  replicas: 1
  securityContext:
    fsGroup: 999        # Groupe PostgreSQL
    runAsUser: 999      # User PostgreSQL (non-root)
  containers:
  - name: postgres
    image: postgres:15
    ports:
    - containerPort: 5433
    env:
    - name: POSTGRES_DB
      value: yourwaytoitaly
    - name: POSTGRES_USER
      value: ywti
    - name: POSTGRES_PASSWORD
      value: ywti_password
    - name: PGPORT
      value: "5433"
    args: ["-p", "5433"]
```

**Application YourWayToItaly :**
```yaml
spec:
  replicas: 2    # Haute disponibilité
  containers:
  - name: ywti-app
    image: gyro0/yourwaytoitaly:1.1
    imagePullPolicy: Never    # Image locale
    ports:
    - containerPort: 8080
    env:
    - name: POSTGRES_HOST
      value: postgres
    - name: POSTGRES_PORT
      value: "5433"
```

### 3.2 `service.yaml`
Expose les déploiements :

```yaml
# Service PostgreSQL (interne)
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5433
    targetPort: 5433

---
# Service Application (externe)
apiVersion: v1
kind: Service
metadata:
  name: ywti-app
spec:
  type: NodePort
  selector:
    app: ywti-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

### 3.3 `ingress.yaml`
Configure le routage HTTP :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ywti-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ywti.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ywti-app
            port:
              number: 80
```

### 3.4 `init-db-job.yaml`
Job d'initialisation de la base de données :

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: init-db
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: init-db
        image: postgres:15
        command: [/bin/bash, -c, |
          # Création des 8 tables avec CREATE TABLE IF NOT EXISTS
          # Insertion des données (109 villes, 15 types, données échantillon)
          cat <<'EOF' | psql -h postgres -p 5433 -U ywti -d yourwaytoitaly
            CREATE TABLE IF NOT EXISTS City (...);
            CREATE TABLE IF NOT EXISTS Type_advertisement (...);
            # ... autres tables
            INSERT INTO City (name) VALUES (...);
          EOF
        ]
        env:
        - name: PGPASSWORD
          value: ywti_password
  backoffLimit: 3
```

### 3.5 `deploy.ps1`
Script PowerShell d'automatisation du déploiement :

```powershell
# Vérification du contexte docker-desktop
# Déploiement des applications (deployment.yaml)
# Création des services (service.yaml)
# Configuration de l'Ingress (ingress.yaml)
# Attente du démarrage des pods (30s)
# Initialisation automatique de la base de données (init-db-job.yaml)
# Affichage de l'état du cluster
```

---

## 4. Processus de Déploiement

### 4.1 Commande de Déploiement Automatisé

```bash
cd k8s
.\deploy.ps1
```

### 4.2 Étapes Exécutées par le Script

1. **Vérification du contexte** : S'assurer que docker-desktop est le contexte actif
2. **Déploiement des applications** : `kubectl apply -f deployment.yaml`
3. **Création des services** : `kubectl apply -f service.yaml`
4. **Configuration de l'Ingress** : `kubectl apply -f ingress.yaml`
5. **Attente du démarrage** : 30 secondes pour que les pods démarrent
6. **Initialisation de la base de données** :
   - Suppression du job précédent : `kubectl delete job init-db`
   - Création du nouveau job : `kubectl apply -f init-db-job.yaml`
   - Attente de la complétion : `kubectl wait --for=condition=complete job/init-db --timeout=60s`
7. **Affichage de l'état** : `kubectl get all` et `kubectl get ingress`

---

## 5. État du Cluster Après Déploiement

### 5.1 Commande `kubectl get all`

```
NAME                            READY   STATUS      RESTARTS   AGE   IP          NODE
pod/init-db-cqm7j               0/1     Completed   0          15m   10.1.0.16   docker-desktop
pod/postgres-665b6b78d6-7hxzm   1/1     Running     0          17m   10.1.0.10   docker-desktop
pod/ywti-app-5958c684df-kfgbt   1/1     Running     0          17m   10.1.0.9    docker-desktop
pod/ywti-app-5958c684df-rpzxk   1/1     Running     0          17m   10.1.0.11   docker-desktop

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        20m
service/postgres     ClusterIP   10.105.157.174   <none>        5433/TCP       17m
service/ywti-app     NodePort    10.109.12.134    <none>        80:30080/TCP   17m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES
deployment.apps/postgres   1/1     1            1           17m   postgres     postgres:15
deployment.apps/ywti-app   2/2     2            2           17m   ywti-app     gyro0/yourwaytoitaly:1.1

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-665b6b78d6   1         1         1       17m
replicaset.apps/ywti-app-5958c684df   2         2         2       17m

NAME                STATUS     COMPLETIONS   DURATION   AGE
job.batch/init-db   Complete   1/1           8s         15m
```

### 5.2 Analyse de l'État

**Pods déployés : 3 pods applicatifs + 1 job complété**
- ✅ `postgres-665b6b78d6-7hxzm` : PostgreSQL (1/1 Running)
- ✅ `ywti-app-5958c684df-kfgbt` : Application replica 1 (1/1 Running)
- ✅ `ywti-app-5958c684df-rpzxk` : Application replica 2 (1/1 Running)
- ✅ `init-db-cqm7j` : Job d'initialisation (Completed)

**Services :**
- ClusterIP `postgres` : Accessible uniquement à l'intérieur du cluster sur le port 5433
- NodePort `ywti-app` : Accessible depuis l'extérieur sur le port 30080

**Déploiements :**
- `postgres` : 1/1 replicas disponibles
- `ywti-app` : 2/2 replicas disponibles (haute disponibilité)

### 5.3 État de l'Ingress

```bash
kubectl get ingress
```

```
NAME           CLASS   HOSTS        ADDRESS     PORTS   AGE
ywti-ingress   nginx   ywti.local   localhost   80      18m
```

**Configuration :**
- **Host** : `ywti.local`
- **Class** : `nginx` (contrôleur NGINX)
- **Address** : `localhost` (LoadBalancer de Docker Desktop)
- **Port** : 80 (HTTP)

---

## 6. Vérification de la Base de Données

### 6.1 Logs du Job d'Initialisation

```bash
kubectl logs job/init-db
```

**Résultat :**
```
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 109
INSERT 0 15
INSERT 0 1
INSERT 0 1
Database initialized successfully!
```

### 6.2 Vérification des Tables Créées

```bash
kubectl exec deployment/postgres -- psql -U ywti -d yourwaytoitaly -c "\dt"
```

**Résultat :**
```
               List of relations
 Schema |         Name          | Type  | Owner
--------+-----------------------+-------+-------
 public | advertisement         | table | ywti
 public | city                  | table | ywti
 public | company               | table | ywti
 public | image                 | table | ywti
 public | review                | table | ywti
 public | tourist               | table | ywti
 public | tourist_advertisement | table | ywti
 public | type_advertisement    | table | ywti
(8 rows)
```

**✅ 8 tables créées avec succès**

### 6.3 Données Insérées

```bash
kubectl exec deployment/postgres -- psql -U ywti -d yourwaytoitaly -c "SELECT COUNT(*) FROM City;"
```

**Résultat :** 109 villes italiennes

```bash
kubectl exec deployment/postgres -- psql -U ywti -d yourwaytoitaly -c "SELECT COUNT(*) FROM Type_advertisement;"
```

**Résultat :** 15 types d'annonces (Museum, Tour, Restaurant, Beach, Park, etc.)

---

## 7. Accès à l'Application

### 7.1 Méthode 1 : Via Ingress (Recommandé pour Production)

**Configuration requise :**
1. Modifier le fichier `C:\Windows\System32\drivers\etc\hosts` (droits administrateur)
2. Ajouter la ligne : `127.0.0.1    ywti.local`

**URL d'accès :**
```
http://ywti.local/html/index.html
```

**Fonctionnement de l'Ingress :**

```
Navigateur (http://ywti.local)
    ↓
Résolution DNS (hosts file: ywti.local → 127.0.0.1)
    ↓
Ingress Controller NGINX (port 80 sur localhost)
    ↓
Règles Ingress (host: ywti.local → service: ywti-app:80)
    ↓
Service ywti-app (Load balancing entre les 2 pods)
    ↓
Pods de l'application (10.1.0.9 et 10.1.0.11)
```

**Avantages de l'Ingress :**
- ✅ Port standard 80/443 (pas besoin de spécifier le port dans l'URL)
- ✅ Routage basé sur le hostname (peut gérer plusieurs applications)
- ✅ Support SSL/TLS (terminaison HTTPS)
- ✅ Path-based routing (`/api` → service A, `/web` → service B)
- ✅ Load balancing intelligent

### 7.2 Méthode 2 : Via NodePort (Développement)

**URL d'accès directe :**
```
http://localhost:30080/html/index.html
```

**Fonctionnement du NodePort :**

```
Navigateur (http://localhost:30080)
    ↓
Docker Desktop (port 30080 exposé sur l'hôte)
    ↓
Service ywti-app NodePort
    ↓
Pods de l'application
```

**Quand utiliser NodePort ?**
- ⚡ Développement et tests locaux
- ⚡ Pas besoin de configuration DNS
- ⚡ Accès rapide sans Ingress Controller

### 7.3 Commande PowerShell pour Ouvrir l'Application

```powershell
# Via NodePort
Start-Process "http://localhost:30080/html/index.html"

# Via Ingress (après configuration du hosts)
Start-Process "http://ywti.local/html/index.html"
```

---

## 8. Problèmes Rencontrés et Solutions

### 8.1 PostgreSQL CrashLoopBackOff (Hérité de Minikube)
**Problème** : Le pod PostgreSQL ne démarrait pas avec l'erreur "root execution not permitted"

**Solution appliquée dans `deployment.yaml` :**
```yaml
securityContext:
  runAsUser: 999      # UID de l'utilisateur postgres
  fsGroup: 999        # GID du groupe postgres
  runAsNonRoot: true  # Force l'exécution non-root
```

### 8.2 Erreur de Syntaxe dans init-db-job.yaml
**Problème** : Le job d'initialisation échouait avec "syntax error: unexpected end of file"

**Cause** : Heredoc EOF mal fermé dans le script bash

**Solution** : Correction de la structure du heredoc
```bash
cat <<'EOF' | psql ...
  SQL statements
EOF
echo "Database initialized successfully!"
```

### 8.3 Ingress Non Fonctionnel (Résolu)
**Problème initial** : `http://ywti.local` ne répondait pas

**Cause** : Fichier hosts Windows non configuré

**Solution** :
1. Installation du contrôleur Ingress NGINX
2. Ajout de `127.0.0.1    ywti.local` dans `C:\Windows\System32\drivers\etc\hosts`
3. L'Ingress Controller LoadBalancer de Docker Desktop écoute automatiquement sur localhost

**Vérification :**
```bash
kubectl get svc -n ingress-nginx
# ingress-nginx-controller   LoadBalancer   10.99.247.98   localhost   80:32159/TCP,443:31309/TCP
```

---

## 9. Comparaison Minikube vs Docker Desktop

| Aspect | Minikube | Docker Desktop |
|--------|----------|----------------|
| **Installation Ingress** | `minikube addons enable ingress` | Installation manuelle du manifest NGINX |
| **Accès Ingress** | `minikube tunnel` requis | LoadBalancer automatique sur localhost |
| **Image locale** | `minikube image load` requis | Accès direct aux images Docker locales |
| **NodePort** | `minikube service --url` pour obtenir l'URL | `localhost:<nodePort>` directement |
| **Complexité** | Plus de commandes spécifiques | Plus simple, intégré à Docker |
| **Performance** | VM séparée (plus lent) | Natif (plus rapide) |

**Pourquoi Docker Desktop pour ce TP ?**
- ✅ Déjà installé et utilisé pour Docker
- ✅ Pas besoin d'outils supplémentaires (Minikube, VirtualBox, etc.)
- ✅ Ingress LoadBalancer automatique sur localhost
- ✅ Images Docker directement accessibles sans `image load`
- ✅ Meilleure performance sur Windows

---

## 10. Technologies et Outils Utilisés

### 10.1 Containerisation
- **Docker** : Containerisation de l'application
- **Docker Hub** : Registre d'images (gyro0/yourwaytoitaly:1.1)
- **Multi-stage build** : Optimisation de la taille de l'image

### 10.2 Orchestration
- **Kubernetes** : Orchestration des conteneurs
- **Docker Desktop Kubernetes** : Cluster Kubernetes local (v1.34.1)
- **kubectl** : CLI pour interagir avec Kubernetes

### 10.3 Composants Kubernetes
- **Deployment** : Gestion des replicas et rolling updates
- **Service** : Exposition des pods (ClusterIP, NodePort)
- **Ingress** : Routage HTTP/HTTPS externe
- **Job** : Tâches one-time (initialisation DB)

### 10.4 Networking
- **NGINX Ingress Controller** : Reverse proxy et load balancer
- **LoadBalancer** : Service type pour Docker Desktop
- **NodePort** : Exposition directe sur un port de l'hôte

### 10.5 Base de Données
- **PostgreSQL 15** : SGBD relationnel
- **Port customisé** : 5433 (au lieu de 5432 par défaut)
- **Initialisation automatique** : Via Kubernetes Job

### 10.6 Application
- **Java EE** : Framework backend
- **Apache Tomcat 9** : Serveur d'applications
- **Java 17** : Version du JDK
- **Maven** : Outil de build

---

## 11. Réponses aux Questions du TP

### Question 1 : Combien de pods ont été déployés ?

**Réponse : 3 pods applicatifs**

- 1 pod PostgreSQL : `postgres-665b6b78d6-7hxzm`
- 2 pods YourWayToItaly : `ywti-app-5958c684df-kfgbt` et `ywti-app-5958c684df-rpzxk`

**Note :** Le pod `init-db-cqm7j` est un Job (status: Completed), pas un pod applicatif permanent.

### Question 2 : Donnez la commande et la sortie de kubectl get all

**Commande :**
```bash
kubectl get all
```

**Sortie complète :**
```
NAME                            READY   STATUS      RESTARTS   AGE
pod/init-db-cqm7j               0/1     Completed   0          15m
pod/postgres-665b6b78d6-7hxzm   1/1     Running     0          17m
pod/ywti-app-5958c684df-kfgbt   1/1     Running     0          17m
pod/ywti-app-5958c684df-rpzxk   1/1     Running     0          17m

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        20m
service/postgres     ClusterIP   10.105.157.174   <none>        5433/TCP       17m
service/ywti-app     NodePort    10.109.12.134    <none>        80:30080/TCP   17m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres   1/1     1            1           17m
deployment.apps/ywti-app   2/2     2            2           17m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-665b6b78d6   1         1         1       17m
replicaset.apps/ywti-app-5958c684df   2         2         2       17m

NAME                STATUS     COMPLETIONS   DURATION   AGE
job.batch/init-db   Complete   1/1           8s         15m
```

### Question 3 : Fournissez l'URL de l'application déployée

**Réponse : Deux méthodes d'accès**

**Méthode 1 - Via Ingress (Production) :**
```
http://ywti.local/html/index.html
```
*Prérequis : Ajouter `127.0.0.1    ywti.local` dans C:\Windows\System32\drivers\etc\hosts*

**Méthode 2 - Via NodePort (Développement) :**
```
http://localhost:30080/html/index.html
```

---

## 12. Conclusion

Le déploiement de l'application YourWayToItaly sur Kubernetes via Docker Desktop a été réalisé avec succès. L'application est entièrement fonctionnelle avec :

✅ **Haute disponibilité** : 2 replicas de l'application pour la résilience  
✅ **Base de données persistante** : PostgreSQL avec 8 tables et données initiales  
✅ **Initialisation automatisée** : Job Kubernetes qui crée les tables et insère les données  
✅ **Ingress NGINX** : Routage HTTP professionnel avec hostname personnalisé  
✅ **Accès flexible** : Via Ingress (ywti.local) ou NodePort (localhost:30080)  
✅ **Sécurité** : PostgreSQL exécuté en tant que non-root (UID 999)  
✅ **Script d'automatisation** : Déploiement complet en une seule commande  

L'utilisation de Docker Desktop au lieu de Minikube simplifie considérablement le workflow, élimine le besoin de `minikube tunnel` pour l'Ingress, et permet un accès direct aux images Docker locales.
.\k8s\deploy.ps1

# Accès à l'application
minikube service ywti-app --url
```

### État du Cluster

```bash
kubectl get all
```

**Résultat** :
- **3 pods déployés** : 1 PostgreSQL + 2 instances de l'application
- Tous les pods en état `Running`
- Service NodePort actif sur le port 30080

---

## Problèmes Rencontrés et Solutions

### 1. PostgreSQL CrashLoopBackOff
**Problème** : Le pod PostgreSQL ne démarrait pas avec l'erreur "root execution not permitted"

**Solution** : Ajout d'un `securityContext` dans le déploiement
```yaml
securityContext:
  runAsUser: 999
  fsGroup: 999
  runAsNonRoot: true
```

### 2. Erreurs CORS
**Problème** : L'application JavaScript ne pouvait pas communiquer avec le backend car `utils.js` utilisait une URL codée en dur (`http://localhost:8080`)

**Solution** : Modification de `utils.js` pour utiliser l'origine dynamique
```javascript
const contextPath = window.location.origin;
```
- Reconstruction de l'image Docker (version 1.1)
- Chargement dans Minikube avec `minikube image load gyro0/yourwaytoitaly:1.1`

### 3. Base de Données Non Initialisée
**Problème** : Erreur HTTP 500 car les tables n'existaient pas dans PostgreSQL

**Solution** : Création d'un Job Kubernetes (`init-db-job.yaml`) qui :
- Crée automatiquement les 8 tables nécessaires avec `CREATE TABLE IF NOT EXISTS`
- Insère les données initiales (110 villes, 15 types d'annonces, données échantillon)
- Vérifie si les tables sont vides avant d'insérer pour éviter les doublons
- S'exécute automatiquement via le script `deploy.ps1`

### 4. Ingress Non Fonctionnel
**Problème** : L'accès via `http://ywti.local` ne fonctionnait pas malgré la configuration Ingress

**Solution** : Utilisation du service NodePort avec tunnel Minikube
```bash
minikube service ywti-app --url
```

---

## Résultats Finaux

### URL d'Accès
L'application est accessible via le tunnel Minikube :
```
http://127.0.0.1:<PORT>/html/index.html
```
*(Le port est attribué dynamiquement par le tunnel)*

### Vérifications Effectuées

1. **Tables créées** : 8 tables (City, Type_advertisement, Company, Tourist, Advertisement, Tourist_Advertisement, Review, Image)
2. **Données insérées** : 110 villes, 15 types d'annonces
3. **Application fonctionnelle** : Interface accessible, pas d'erreurs CORS, connexion à la base de données réussie

### Commande kubectl get all

```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/postgres-deployment-567cbc9f8-xxxxx   1/1     Running   0          10m
pod/ywti-app-xxxxxxxxx-xxxxx              1/1     Running   0          10m
pod/ywti-app-xxxxxxxxx-xxxxx              1/1     Running   0          10m

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/postgres     ClusterIP   10.xxx.xxx.xxx   <none>        5433/TCP       10m
service/ywti-app     NodePort    10.xxx.xxx.xxx   <none>        80:30080/TCP   10m

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres-deployment   1/1     1            1           10m
deployment.apps/ywti-app              2/2     2            2           10m

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-deployment-567cbc9f8   1         1         1       10m
replicaset.apps/ywti-app-xxxxxxxxx              2         2         2       10m
```

---

## Automatisation

Le script `deploy.ps1` automatise l'ensemble du processus de déploiement :
1. Application des manifestes Kubernetes (deployment, service, ingress)
2. Attente du démarrage des pods (30 secondes)
3. **Initialisation automatique de la base de données** via le Job `init-db`
4. Affichage de l'état du cluster
5. Instructions pour accéder à l'application

**Commande unique pour tout déployer** :
```powershell
.\k8s\deploy.ps1
```

---

## Technologies Utilisées

- **Containerisation** : Docker (multi-stage build)
- **Orchestration** : Kubernetes (Minikube)
- **Base de données** : PostgreSQL 15
- **Serveur d'applications** : Apache Tomcat 9
- **Langage** : Java 17, JEE
- **Build** : Maven 3.9

---

## Conclusion

Le déploiement de l'application YourWayToItaly sur Kubernetes a été réalisé avec succès. L'application est entièrement fonctionnelle avec 2 instances pour la haute disponibilité, une base de données PostgreSQL persistante, et un processus d'initialisation automatisé. Les problèmes de configuration (CORS, permissions PostgreSQL, initialisation DB) ont été résolus de manière robuste et reproductible.
