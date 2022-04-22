# Домашняя работа по занятию 15.2 "Вычислительные мощности. Балансировщики нагрузки".

> ## Задание 1. Яндекс.Облако (обязательное к выполнению)
> 1. Создать bucket Object Storage и разместить там файл с картинкой:
> - Создать bucket в Object Storage с произвольным именем (например, _имя_студента_дата_);
> - Положить в bucket файл с картинкой;
> - Сделать файл доступным из Интернет.
> 2. Создать группу ВМ в public подсети фиксированного размера с шаблоном LAMP и web-страничкой, содержащей ссылку на картинку из bucket:
> - Создать Instance Group с 3 ВМ и шаблоном LAMP. Для LAMP рекомендуется использовать `image_id = fd827b91d99psvq5fjit`;
> - Для создания стартовой веб-страницы рекомендуется использовать раздел `user_data` в [meta_data](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata);
> - Разместить в стартовой веб-странице шаблонной ВМ ссылку на картинку из bucket;
> - Настроить проверку состояния ВМ.
> 3. Подключить группу к сетевому балансировщику:
> - Создать сетевой балансировщик;
> - Проверить работоспособность, удалив одну или несколько ВМ.
> 4. *Создать Application Load Balancer с использованием Instance group и проверкой состояния.

[Ресурсы терраформа](yc)

Применяем конфигурацию:
```
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

ALB_addr = tolist([
  tolist([
    tolist([
      tolist([
        "51.250.11.199",
      ]),
    ]),
  ]),
])
LAMP_nodes = {
  "cl1nih80kco9528th0vq-idok.ru-central1.internal" = "51.250.10.23"
  "cl1nih80kco9528th0vq-ugej.ru-central1.internal" = "51.250.5.140"
  "cl1nih80kco9528th0vq-ymyb.ru-central1.internal" = "51.250.3.10"
}
LB_addr = tolist([
  tolist([
    "51.250.3.3",
  ]),
])
```
(довольно уродливый вывод некоторых аутпутов, но я не знаю как красиво показать 
`yandex_alb_load_balancer.lamp.listener[*].endpoint[*].address[*].external_ipv4_address[*].address`. Наверное, 4 вложенных цикла не лучше будет.)

Проверяем доступность нашего сайта через Network Load Balancer:
```
$ curl 51.250.3.3
<html><body><h1>ELK</h1><p>This is elk:</p><img src='https://storage.yandexcloud.net/netology-15-02/elk.jpg'>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
```

Проверяем доступность нашего сайта через Application Load Balancer:
```
$ curl 51.250.11.199
<html><body><h1>ELK</h1><p>This is elk:</p><img src='https://storage.yandexcloud.net/netology-15-02/elk.jpg'>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
```

Проверяем MD5 сумму нашей картинки, залитой в storage bucket:
```
$ cat ../elk.jpg |md5sum -
7ea8db72555db4cc1da3299ca5304732  -
$ curl -s https://storage.yandexcloud.net/netology-15-02/elk.jpg |md5sum -
7ea8db72555db4cc1da3299ca5304732  -
```

Проверим балансировку через NLB и ALB:
```
$ for i in $(seq 1 10); do curl -s 51.250.3.3 |grep lives;  done 
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>

$ for i in $(seq 1 10); do curl -s 51.250.11.199 |grep lives;  done 
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ugej</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
```

Отвечают все три хоста. Теперь проверим балансировку с одной отключенной виртуалкой:
```
$ for i in $(seq 1 10); do curl -s 51.250.3.3 |grep lives;  done 
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>

$ for i in $(seq 1 10); do curl -s 51.250.11.199 |grep lives;  done 
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-ymyb</p></body></html>
<p>This elk lives at cl1nih80kco9528th0vq-idok</p></body></html>
```
Теперь отвечают только оставшиеся два хоста. Кстати, ALB с виду поплавней размазал нагрузку.

---
> ## Задание 2*. AWS (необязательное к выполнению)

> Используя конфигурации, выполненные в рамках ДЗ на предыдущем занятии, добавить к Production like сети Autoscaling group из 3 EC2-инстансов с  автоматической установкой web-сервера в private домен.
> 1. Создать bucket S3 и разместить там файл с картинкой:
> - Создать bucket в S3 с произвольным именем (например, _имя_студента_дата_);
> - Положить в bucket файл с картинкой;
> - Сделать доступным из Интернета.
> 2. Сделать Launch configurations с использованием bootstrap скрипта с созданием веб-странички на которой будет ссылка на картинку в S3. 
> 3. Загрузить 3 ЕС2-инстанса и настроить LB с помощью Autoscaling Group.


[Ресурсы терраформа](aws)

Применяем конфигурацию терраформа:
```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

LB_addr = "web-1197899779.eu-central-1.elb.amazonaws.com"
```

Проверяем доступность web-сервиса через Load Balancer:
```
$ curl web-1197899779.eu-central-1.elb.amazonaws.com
<html><body><h1>ELK</h1><p>This is elk:</p><img src='https://netology-15-02.s3.eu-central-1.amazonaws.com/elk.jpg'>
<p>This elk lives at ip-10-10-1-107</p></body></html>
```

Проверяем MD5 сумму нашей картинки, залитой в S3 bucket:
```
$ cat ../elk.jpg |md5sum -
7ea8db72555db4cc1da3299ca5304732  -
$ curl -s https://netology-15-02.s3.eu-central-1.amazonaws.com/elk.jpg |md5sum -
7ea8db72555db4cc1da3299ca5304732  -
```

Проверяем балансировку со всеми тремя, и одним отключенным хостами:
```
$ for i in $(seq 1 10); do curl -s web-1197899779.eu-central-1.elb.amazonaws.com |grep lives;  done 
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-107</p></body></html>
<p>This elk lives at ip-10-10-1-107</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-107</p></body></html>
<p>This elk lives at ip-10-10-1-107</p></body></html>


$ for i in $(seq 1 10); do curl -s web-1197899779.eu-central-1.elb.amazonaws.com |grep lives;  done 
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-4</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
<p>This elk lives at ip-10-10-1-100</p></body></html>
```

Всё работает ожидаемо. 