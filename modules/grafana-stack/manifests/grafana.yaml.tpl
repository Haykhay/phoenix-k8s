serviceAccount:
  create: true
  name: grafana
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Mimir
        type: prometheus
        uid: mimir
        url: http://mimir-gateway.${namespace}.svc/prometheus
        isDefault: true
      - name: Loki
        type: loki
        uid: loki
        url: http://loki-gateway.${namespace}.svc
      - name: Tempo
        type: tempo
        uid: tempo
        url: http://tempo.${namespace}.svc:3200
      # The cloud's own monitoring, read with grafana's cloud identity.
      ${indent(6, yamlencode(cloud_datasources))}
