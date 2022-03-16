# Домашняя работа по занятию "14.2 Синхронизация секретов с внешними сервисами. Vault"

> ## Задача 1: Работа с модулем Vault
> ## Задача 2 (*): Работа с секретами внутри модуля

Наш [vault-клиент](vault-client.py) будет читать из Vault'а свой секрет и отдавать его по HTTP API (`/get_secret` endpoint). 

[Соберём](Dockerfile) с этим клиентом и всеми его питоно-зависимостями [образ контейнера](https://hub.docker.com/r/prividen/test-vault-client).

Наше [тестовое приложение](testapp.yaml) будет содержать:
- секрет с токеном к Vault, и с тем секретом, который мы будем хранить в Vault и показывать через HTTP API;
- деплоймент для Vault,
- деплоймент для vault-клиента,
- и сервисы для обоих.

У пода с vault-клиентом будет init-контейнер, который при инициализации создаёт секрет в Vault.

Запускаем приложение:

```
$ kubectl -n 14-02 apply -f testapp.yaml 
secret/vault-secret created
deployment.apps/vault created
deployment.apps/test-vault-client created
service/vault created
service/test-vault-client created

$ kubectl -n 14-02 get all
NAME                                   READY   STATUS    RESTARTS   AGE
pod/test-vault-client-7755cb4f-2l7wk   1/1     Running   0          17s
pod/vault-6bd5f4d66-p4zlr              1/1     Running   0          17s

NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
service/test-vault-client   LoadBalancer   10.233.11.186   10.12.60.128   80:32319/TCP   17s
service/vault               ClusterIP      10.233.44.17    <none>         8200/TCP       17s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/test-vault-client   1/1     1            1           17s
deployment.apps/vault               1/1     1            1           17s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/test-vault-client-7755cb4f   1         1         1       17s
replicaset.apps/vault-6bd5f4d66              1         1         1       17s
```

И пробуем получить секрет:
```
$ curl -s 10.12.60.128/get_secret |jq
{
  "netology_secret": "Big secret!!!"
}
```

Надо же, работает.
