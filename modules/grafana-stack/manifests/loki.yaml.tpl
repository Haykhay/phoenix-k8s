# Single binary, objects under <bucket>/${loki_prefix}/ (Loki's storage_prefix
# allows no slash, so the cluster name is part of it).
deploymentMode: SingleBinary
serviceAccount:
  create: true
  name: loki
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  schemaConfig:
    configs:
      - from: "2026-01-01"
        store: tsdb
        object_store: ${loki_schema_store}
        schema: v13
        index:
          prefix: index_
          period: 24h
  storage:
    ${indent(4, yamlencode(loki_storage))}
singleBinary:
  replicas: 1
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0
chunksCache:
  enabled: false
resultsCache:
  enabled: false
lokiCanary:
  enabled: false
test:
  enabled: false
minio:
  enabled: false
