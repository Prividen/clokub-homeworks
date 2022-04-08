# Домашняя работа по занятию "15.1. Организация сети"

> ## Задание 1. Яндекс.Облако (обязательное к выполнению)
[Ресурсы терраформа](yc)

Деплоим:
```
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

public_nat_ip = "51.250.67.117"
test_private_ip = "192.168.20.18"
test_public_ip = "51.250.67.191"
```

Тестируем. Заходим на виртуалку в публичной подсети, убеждаемся что есть выход в интернет, проверяем внешний IP:
```
$ ssh -A cloud-user@51.250.67.191
[cloud-user@test-public-vm ~]$ curl ifconfig.co
51.250.67.191
```

Оттуда заходим на виртуалку в приватной подсети, убеждаемся что есть выход в интернет, проверяем внешний IP:
```
[cloud-user@test-public-vm ~]$ ssh 192.168.20.18
[cloud-user@test-private-vm ~]$ curl ifconfig.co
51.250.67.117
```
совпадает с публичным адресом NAT-инстанса

Пробуем подключиться напрямую к этому адресу:
```
$ ssh ubuntu@51.250.67.117
Welcome to Ubuntu 18.04.1 LTS (GNU/Linux 4.15.0-29-generic x86_64)
...
#################################################################
This instance runs Yandex.Cloud Marketplace product
Please wait while we configure your product...

Documentation for Yandex Cloud Marketplace images available at https://cloud.yandex.ru/docs

#################################################################
...
ubuntu@nat-instance:~$ 
```
Попадаем внутрь nat-инстанса.


---
> ## Задание 2*. AWS (необязательное к выполнению)

[Ресурсы терраформа](aws)

Деплоим:
```
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

public_nat_ip = "3.124.154.201"
test_private_ip = "10.10.2.169"
test_public_ip = "35.159.12.62"
```

Проверяем. Заходим на виртуалку в публичной подсети, убеждаемся что есть выход в интернет, проверяем внешний IP:
```
$ ssh -A ec2-user@35.159.12.62
[ec2-user@ip-10-10-1-83 ~]$ curl ifconfig.co
35.159.12.62
```

Оттуда переходим на виртуалку в приватной подсети, убеждаемся что есть выход в интернет, проверяем внешний IP:
```
[ec2-user@ip-10-10-1-83 ~]$ ssh 10.10.2.169
[ec2-user@ip-10-10-2-169 ~]$ curl ifconfig.co
3.124.154.201
```
совпадает с публичным адресом NAT-гейтвея

Пробуем подключиться к нему напрямую:
```
$ ssh -o ConnectTimeout=5 -A ec2-user@3.124.154.201
ssh: connect to host 3.124.154.201 port 22: Connection timed out
```
Безуспешно. Б - Безопасность.
