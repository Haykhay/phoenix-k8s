# mimir-distributed: chart-default architecture (ingest storage through the
# chart's own Kafka). Objects land under <bucket>/${mimir_prefix}/${cluster_name}/:
# the prefix may only be alphanumeric, so the cluster name is the tenant.
serviceAccount:
  create: true
  name: mimir
minio:
  enabled: false
# Alertmanager and ruler would store state outside the cluster's prefix;
# alerting is done in Grafana instead.
alertmanager:
  enabled: false
ruler:
  enabled: false
mimir:
  structuredConfig:
    multitenancy_enabled: false
    no_auth_tenant: ${cluster_name}
    usage_stats:
      enabled: false
    common:
      storage:
        ${indent(8, yamlencode(mimir_storage))}
    blocks_storage:
      storage_prefix: ${mimir_prefix}
