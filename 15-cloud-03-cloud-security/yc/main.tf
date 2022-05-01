locals {
  zone           = "ru-central1-a"
  lamp_image_id  = "fd827b91d99psvq5fjit"
  public_subnet  = ["192.168.10.0/24"]
  private_subnet = ["192.168.20.0/24"]
  nat_gw         = "192.168.10.254"
  dns_zone       = "yc.complife.ru"
  site_name      = "elk"
  site_url       = "${local.site_name}.${local.dns_zone}"
  site_content   = <<EOT
<html><body><h1>ELK</h1><p>This is elk:</p>
<a href='elk.jpg'><img src='elk.jpg' width='15%'></a>
<p>This elk lives at object storage</p></body></html>
EOT
}

provider "yandex" {
  cloud_id  = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone      = local.zone
}


# create service account with key and role assigment

resource "yandex_iam_service_account" "sa-15" {
  name = "sa-15"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id  = yandex_iam_service_account.sa-15.folder_id
  role       = "editor"
  member     = "serviceAccount:${yandex_iam_service_account.sa-15.id}"
  depends_on = [yandex_iam_service_account.sa-15]
}


resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa-15.id
  description        = "static access key for object storage"
  depends_on         = [yandex_iam_service_account.sa-15]
}


resource "yandex_kms_symmetric_key" "bucket-key" {
  name = "bucket-key"
}

# Create storage bucket with a picture

resource "yandex_storage_bucket" "netology-15-encrypted" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on = [yandex_iam_service_account_static_access_key.sa-static-key]
  bucket     = "netology-15-encrypted"
  acl        = "public-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket-key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_bucket" "netology-15-site" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on = [yandex_iam_service_account_static_access_key.sa-static-key]
  bucket     = local.site_url
  acl        = "public-read"

  website {
    index_document = "index.html"
  }
}


resource "yandex_storage_object" "elk" {
  for_each = toset( [
    yandex_storage_bucket.netology-15-encrypted.bucket,
    yandex_storage_bucket.netology-15-site.bucket
  ] )
  access_key   = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on   = [yandex_iam_service_account_static_access_key.sa-static-key]

  bucket       = each.key
  key          = "elk.jpg"
  content_type = "image/jpeg"
  source       = "../elk.jpg"
  acl          = "public-read"
}

resource "yandex_storage_object" "index-page" {
  access_key   = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on   = [yandex_iam_service_account_static_access_key.sa-static-key]

  bucket       = yandex_storage_bucket.netology-15-site.bucket
  key          = "index.html"
  content_type = "text/html"
  acl          = "public-read"
  content      = local.site_content
}



resource "yandex_dns_zone" "yc-zone" {
  name  = "yc-zone"
  zone  = "${local.dns_zone}."
  public  = true
}


resource "yandex_dns_recordset" "elk-site" {
  zone_id = yandex_dns_zone.yc-zone.id
  name    = local.site_name
  type    = "CNAME"
  ttl     = 200
  data    = ["${local.site_url}.website.yandexcloud.net"]
}

