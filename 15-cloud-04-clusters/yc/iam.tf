# Создать отдельный сервис-аккаунт с необходимыми правами

resource "yandex_iam_service_account" "sa-15" {
  name = "sa-15"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id  = yandex_iam_service_account.sa-15.folder_id
  role       = "editor"
  member     = "serviceAccount:${yandex_iam_service_account.sa-15.id}"
  depends_on = [yandex_iam_service_account.sa-15]
}

resource "yandex_resourcemanager_folder_iam_member" "sa-images-puller" {
  folder_id  = yandex_iam_service_account.sa-15.folder_id
  role       = "container-registry.images.puller"
  member     = "serviceAccount:${yandex_iam_service_account.sa-15.id}"
  depends_on = [yandex_iam_service_account.sa-15]
}

resource "yandex_kms_symmetric_key" "k8s-key" {
  name = "k8s-key"
}
