global:
  domain: "${url_host}"

configs:
  cm:
    # Required for Kargo: tracks resources via annotations instead of labels
    application.resourceTrackingMethod: annotation
    # Local admin only for now; disable when Entra OIDC is configured
    admin.enabled: "true"
    timeout.reconciliation: "60s"

  params:
    server.insecure: "true"

  secret:
    argocdServerAdminPassword: "${admin_password_hash}"
    argocdServerAdminPasswordMtime: "2024-01-01T00:00:00Z"

  rbac:
    policy.default: role:admin

server:
  # Exposed through istio (HTTPRoute in this module), not an ingress.
  ingress:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi

dex:
  enabled: false

# The cloud slice binds argocd-repo-server to its identity (registry pulls
# for OCI charts): Pod Identity on AWS, so no annotation there.
repoServer:
  serviceAccount:
    name: argocd-repo-server
%{ if length(sa_annotations) > 0 ~}
    annotations:
      ${indent(6, yamlencode(sa_annotations))}
%{ endif ~}
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

controller:
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: "1"
      memory: 1Gi

applicationSet:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 250m
      memory: 256Mi

redis:
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi
