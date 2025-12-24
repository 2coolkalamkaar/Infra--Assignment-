#!/bin/bash
set -e

echo "STARTING CLEAN BUILD"

#directories
mkdir -p ~/assignment/helm/wordpress-stack/templates


cat <<EOF > ~/assignment/helm/wordpress-stack/values.yaml
global:
  storageClass: "" 

mysql:
  image: mysql:5.7
  rootPassword: "rootpassword123"
  dbName: wordpress
  user: wp_user
  password: wp_password
  persistence:
    size: 5Gi

wordpress:
  image: wordpress:latest
  replicas: 2
  persistence:
    size: 10Gi
    accessMode: ReadWriteMany

nginx:
  image: kalamkaar/custom-nginx:v1
  replicas: 2
  service:
    type: NodePort
    port: 80
EOF
#PVC
cat <<EOF > ~/assignment/helm/wordpress-stack/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF


cat <<EOF > ~/assignment/helm/wordpress-stack/templates/services.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
spec:
  selector:
    app: wordpress
  ports:
    - port: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx-proxy
  ports:
    - port: 80
      targetPort: 80
EOF

# MySQL
cat <<EOF > ~/assignment/helm/wordpress-stack/templates/mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword123"
        - name: MYSQL_DATABASE
          value: "wordpress"
        - name: MYSQL_USER
          value: "wp_user"
        - name: MYSQL_PASSWORD
          value: "wp_password"
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
EOF

# WordPress
cat <<EOF > ~/assignment/helm/wordpress-stack/templates/wordpress-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        env:
        - name: WORDPRESS_DB_HOST
          value: "mysql-service"
        - name: WORDPRESS_DB_USER
          value: "wp_user"
        - name: WORDPRESS_DB_PASSWORD
          value: "wp_password"
        - name: WORDPRESS_DB_NAME
          value: "wordpress"
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim
EOF

# Nginx
cat <<EOF > ~/assignment/helm/wordpress-stack/templates/nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-proxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-proxy
  template:
    metadata:
      labels:
        app: nginx-proxy
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9113"
    spec:
      containers:
      - name: nginx
        image: kalamkaar/custom-nginx:v1
        ports:
        - containerPort: 80
      - name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.10.0
        args:
          - -nginx.scrape-uri=http://127.0.0.1:80/metrics
        ports:
        - containerPort: 9113
          name: metrics
EOF

# 7. CREATE MANUAL PVs (Outside Helm)
cat <<EOF > ~/assignment/manual-pvs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
  labels:
    type: local
spec:
  storageClassName: ""
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data/mysql"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
  labels:
    type: local
spec:
  storageClassName: ""
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/data/wordpress"
EOF

# 8. APPLY AND INSTALL
echo "Creating PVs Manually..."
kubectl apply -f ~/assignment/manual-pvs.yaml

echo " Installing Helm Chart..."
helm install my-wp-stack ~/assignment/helm/wordpress-stack --namespace infra-assignment

echo "DONE! Checking pods..."
sleep 5
kubectl get pods -n infra-assignment