# Домашняя работа по занятию "14.4 Сервис-аккаунты"

> ## Задача 1: Работа с сервис-аккаунтами через утилиту kubectl в установленном minikube

```
$ kubectl create sa myservice
serviceaccount/myservice created
$ kubectl get serviceaccounts
NAME                                SECRETS   AGE
default                             1         34d
myservice                           1         25s
nfs-server-nfs-server-provisioner   1         34d
$ kubectl get serviceaccount
NAME                                SECRETS   AGE
default                             1         34d
myservice                           1         28s
nfs-server-nfs-server-provisioner   1         34d

$ kubectl get serviceaccount default -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-02-19T08:06:05Z"
  name: default
  namespace: default
  resourceVersion: "396"
  uid: b3f2df21-0c3b-43d4-aeac-1ee90e1849e0
secrets:
- name: default-token-c44m8

$ kubectl get sa myservice -o json >myservice.json
$ kubectl delete sa myservice
serviceaccount "myservice" deleted
$ kubectl apply -f myservice.json 
serviceaccount/myservice created
```

---
> ## Задача 2 (*): Работа с сервис-акаунтами внутри модуля

Выбрать любимый образ контейнера, подключить сервис-акаунты и проверить
доступность API Kubernetes

```
$ kubectl run -it --rm multitool --image=praqma/network-multitool:alpine-extra \
    --restart=Never --overrides='{ "spec": { "serviceAccount": "myservice" }  }' -- bash
If you don't see a command prompt, try pressing enter.
bash-5.1# set |grep KUBE
KUBERNETES_PORT=tcp://10.233.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.233.0.1:443
KUBERNETES_PORT_443_TCP_ADDR=10.233.0.1
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_SERVICE_HOST=10.233.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443

bash-5.1# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
bash-5.1# CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
bash-5.1# curl --cacert $CA -H "Authorization: Bearer $TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT_HTTPS/api/
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "10.12.60.117:6443"
    }
  ]
}

...

$ kubectl get pod multitool -o jsonpath='{.spec.serviceAccount}'
myservice
```
