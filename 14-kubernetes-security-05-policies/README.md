# Домашняя работа по занятию "14.5 SecurityContext, NetworkPolicies"

> ## Задача 1: Рассмотрите пример 14.5/example-security-context.yml

```
$ kubectl apply -f example-security-context.yml 
pod/security-context-demo created
$ kubectl exec security-context-demo -- id
uid=1000 gid=3000 groups=3000
```

---
> ## Задача 2 (*): Рассмотрите пример 14.5/example-network-policy.yml

> Создайте два модуля. Для первого модуля разрешите доступ к внешнему миру
и ко второму контейнеру. Для второго модуля разрешите связь только с
первым контейнером. Проверьте корректность настроек.

Для душевного здоровья представим, что модуль, под и контейнер - это одно и то же.

Напишем [тестовое приложение](testapp.yaml), которое поднимет 2 пода с nginx на 80 порту, к ним по сервису для 
удобного обращения, и сетевую политику, разрешающую для второго модулеконтейнера исходящий трафик только к первому поду.
Условие "разрешите доступ к внешнему миру и ко второму контейнеру" реализуется по умолчанию, если egress специально не 
ограничивать, он неограниченный. 
Так же открывается доступ к DNS, чтобы можно было резолвить имя сервиса.

Проверяем, что поды могут обращаться друг к другу:

```
$ kubectl exec pod-1 -- curl -s -m 1 pod-2
Praqma Network MultiTool (with NGINX) - pod-2 - 10.233.78.132
$ kubectl exec pod-2 -- curl -s -m 1 pod-1
Praqma Network MultiTool (with NGINX) - pod-1 - 10.233.126.115
```

Проверяем, все ли поды имеют доступ к внешнему миру:
```
$ kubectl exec pod-1 -- curl -s -m 1 10.12.41.201
<html>
<head><title>301 Moved Permanently</title></head>
<body bgcolor="white">
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx/1.12.2</center>
</body>
</html>
$ kubectl exec pod-2 -- curl -s -m 1 10.12.41.201
command terminated with exit code 28
```
У второго пода доступа нету, вылетел с таймаутом.

