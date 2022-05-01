output "elk-picture" {
  value = {
    for k, v in yandex_storage_object.elk:
        "bucket ${k}" => "https://storage.yandexcloud.net/${v.bucket}/${v.id}"
  }
}

output "site" {
  value = local.site_url
}

output "access-key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key
  sensitive = true
}
