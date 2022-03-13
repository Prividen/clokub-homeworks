# Домашняя работа по занятию "14.1 Создание и использование секретов"

> ## Задача 1: Работа с секретами через утилиту kubectl в установленном minikube
> ### Как создать секрет?

```
$ kubectl create secret tls -n 14-01 testapp-cert --cert=cert.crt --key=cert.key 
secret/testapp-cert created
```

> ### Как просмотреть список секретов?

```
$ kubectl get -n 14-01 secret
NAME                  TYPE                                  DATA   AGE
default-token-dvhxq   kubernetes.io/service-account-token   3      8m23s
testapp-cert         kubernetes.io/tls                     2      7m39s
```

### Как просмотреть секрет?

```
$ kubectl get -n 14-01 secret testapp-cert 
NAME            TYPE                DATA   AGE
testapp-cert   kubernetes.io/tls   2      10m


$ kubectl describe -n 14-01 secret testapp-cert 
Name:         testapp-cert
Namespace:    14-01
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1822 bytes
tls.key:  1704 bytes
```

### Как получить информацию в формате YAML и/или JSON?

```
$ kubectl get -n 14-01 secret testapp-cert -o yaml |tail -8
kind: Secret
metadata:
  creationTimestamp: "2022-03-13T01:53:05Z"
  name: testapp-cert
  namespace: 14-01
  resourceVersion: "4715126"
  uid: eed06339-e964-4722-b374-24a286877ea6
type: kubernetes.io/tls

$ kubectl get -n 14-01 secret testapp-cert -o json |jq .metadata
{
  "creationTimestamp": "2022-03-13T01:53:05Z",
  "name": "testapp-cert",
  "namespace": "14-01",
  "resourceVersion": "4715126",
  "uid": "eed06339-e964-4722-b374-24a286877ea6"
}

```

> ### Как выгрузить секрет и сохранить его в файл?
> ### Как удалить секрет?
> ### Как загрузить секрет из файла?

```
$ kubectl get -n 14-01 secret testapp-cert -o yaml >testapp-cert.yaml
$ kubectl delete -n 14-01 secret testapp-cert
secret "testapp-cert" deleted
$ kubectl apply -n 14-01 -f testapp-cert.yaml
secret/testapp-cert created
```

---
> ## Задача 2 (*): Работа с секретами внутри модуля
> Выберите любимый образ контейнера, подключите секреты и проверьте их доступность
> как в виде переменных окружения, так и в виде примонтированного тома.

Будем использовать уже имеющийся tls-секрет с сертификатами, а так же сделаем ещё один секрет, пароль из которого будем
подкладывать в файл на диск из init-контейнера (да, можно было бы и сразу монтировать как файл, но мы же не ищем лёгких путей):

```
$ kubectl create secret generic -n 14-01 password-of-day --from-literal=password='Pa$$w0rd'
secret/password-of-day created
```

И сделаем [тестовое приложение](testapp.yaml), которое будет отдавать этот пароль по HTTPS:
```
$ kubectl apply -n 14-01 -f testapp.yaml 
configmap/testapp-14-01 created
deployment.apps/testapp-14-01 created
service/testapp-14-01 created
```

Проверяем:
```
$ kubectl -n 14-01 get all
NAME                               READY   STATUS    RESTARTS   AGE
pod/testapp-14-01-8b69bcd9-tcbsj   1/1     Running   0          6m55s

NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
service/testapp-14-01   LoadBalancer   10.233.26.241   10.12.60.129   80:31043/TCP,443:30863/TCP   6m55s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/testapp-14-01   1/1     1            1           6m56s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/testapp-14-01-8b69bcd9   1         1         1       6m55s


$ curl https://testapp-14-01.i/passwords/password.txt
Pa$$w0rd
```
действительно, отдаёт.
