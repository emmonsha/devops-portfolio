# Prometheus Operator

Оператор устанавливался из официального upstream-бандла (не включён в репозиторий — 4+ МБ).

Установка:
```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
```

Далее применялись свои ServiceMonitor/правила и CR-объекты кластера.
