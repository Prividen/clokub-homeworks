# Домашняя работа по занятию "14.3 Карты конфигураций"

> ## Задача 1: Работа с картами конфигураций через утилиту kubectl в установленном minikube

```
$ kubectl create configmap nginx --from-file=test-index.html --from-literal=http_port=10080 --from-literal=https_port=10443

$ kubectl get cm
NAME               DATA   AGE
kube-root-ca.crt   1      29d
nginx              3      3m6s

$ kubectl get cm nginx -o json |jq .data.http_port
"10080"

$ kubectl get cm nginx -o yaml >> testapp.yaml

$ kubectl delete cm nginx
configmap "nginx" deleted
```

---
## Задача 2 (*): Работа с картами конфигураций внутри модуля

> Выбрать любимый образ контейнера, подключить карты конфигураций и проверить
их доступность как в виде переменных окружения, так и в виде примонтированного
тома

В качесте _любимого образа контейнера_ будем использовать `praqma/network-multitool`.  
Наше тестовое приложение будет брать из конфиг-мапа номера HTTP/HTTPS портов, как переменные, а index.html - как смонтированный файл.
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx
data:
  http_port: "10080"
  https_port: "10443"
  test-index.html: |+
    <html><head>Test index</head>
    <body><h1>Test index</h1>
    <p>This is test index page, thanks for your visit</p>
    </body></html>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multitool
spec:
  selector:
    matchLabels:
      app: multitool
  replicas: 1
  template:
    metadata:
      labels:
        app: multitool
    spec:
      containers:
        - name: multitool
          image: praqma/network-multitool:alpine-extra
          imagePullPolicy: IfNotPresent
          env:
            - name: HTTP_PORT
              valueFrom:
                configMapKeyRef:
                  name: nginx
                  key: http_port
            - name: HTTPS_PORT
              valueFrom:
                configMapKeyRef:
                  name: nginx
                  key: https_port
          volumeMounts:
            - name: html-root
              mountPath: /usr/share/nginx/html
              readOnly: true
      volumes:
        - name: html-root
          configMap:
            name: nginx
            items:
              - key: test-index.html
                path: index.html
---
apiVersion: v1
kind: Service
metadata:
  name: multitool
spec:
  type: LoadBalancer
  ports:
    - name: multitool-http
      port: 10080
    - name: multitool-https
      port: 10443
  selector:
    app: multitool

```

Проверим:
```
$ kubectl apply -f testapp.yaml 
configmap/nginx created
deployment.apps/multitool created
service/multitool created

$ curl 10.12.60.129:10080
<html><head>Test index</head>
<body><h1>Test index</h1>
<p>This is test index page, thanks for your visit</p>
</body></html>
```