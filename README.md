# DevOps Portfolio — Kubernetes · Helm · CI/CD · IaC

Практические инженерные артефакты: развёртывание микросервисного приложения в Kubernetes,
упаковка в Helm, GitOps/Kustomize, модульный CI/CD в GitLab, инфраструктура как код и мониторинг Linux.

**Автор:** Павел Игнатьев · [github.com/emmonsha](https://github.com/emmonsha)

---

## Что внутри

| Каталог | Что демонстрирует | Стек |
|---|---|---|
| [`helm/`](helm/) | Собственный Helm-чарт: 20+ шаблонов, HPA, PVC, ingress, secrets/configmap, helpers | Helm 3, Kubernetes |
| [`kustomize/`](kustomize/) | Kustomize base + overlays (production): патчи, overlays, управление конфигурацией | Kustomize |
| [`k8s-manifests/`](k8s-manifests/) | Чистые Kubernetes-манифесты микросервисного приложения (8 сервисов + PostgreSQL) | Kubernetes |
| [`k3s-cluster/`](k3s-cluster/) | Сборка кластера K3s: база, БД, networking, TLS-сертификаты, Prometheus Operator, скрипты деплоя | K3s, cert-manager, Prometheus |
| [`ansible/`](ansible/) | Playbook установки K3s + GitLab Runner + registry (IaC) | Ansible |
| [`ci-cd/`](ci-cd/) | Модульный GitLab CI/CD: prepare → build → test → staging, раннеры в Kubernetes | GitLab CI, Kaniko, Docker |
| [`terraform/`](terraform/) | IaC для GCP: кластер, Memorystore (Redis), сети | Terraform |
| [`istio/`](istio/) | Service mesh: gateway, маршрутизация, egress-политики | Istio |
| [`monitoring/`](monitoring/) | Bash-скрипты мониторинга Linux: логи, установка/удаление логгеров, отчёты | Bash, Prometheus, Grafana |

## Архитектура приложения

Микросервисное приложение (booking/hotel/payment/loyalty/session/report/gateway) + PostgreSQL и RabbitMQ.
Разворачивается тремя способами: чистые манифесты → Kustomize → Helm (от простого к управляемому).

```
gateway ─┬─ booking ─── hotel
         ├─ payment
         ├─ loyalty
         ├─ session
         └─ report
                    ↘ PostgreSQL (per-service DB) + RabbitMQ
```

## Быстрый старт (Helm)

```bash
# Проверка чарта
helm lint helm/my-helm-app
helm template my-app helm/my-helm-app

# Установка (значения секретов задаются через --set или values-файл)
helm install my-app helm/my-helm-app \
  --set postgresql.password="<secret>" \
  --set rabbitmq.password="<secret>" \
  --set authKey="<secret>"
```

> ⚠️ Все пароли/токены вынесены в `values.yaml` (плейсхолдер `CHANGE_ME`) или Secrets.
> Реальных секретов в репозитории нет.

## Навыки, которые это подтверждает

`Kubernetes` · `K3s` · `Helm` · `Kustomize` · `Ansible` · `Terraform` · `Docker` ·
`GitLab CI/CD` · `Istio` · `Prometheus` · `Grafana` · `Linux` · `Bash` · `Networking` · `TLS`

## Лицензия

MIT (учебно-практические материалы, форматированы и очищены для портфолио).
