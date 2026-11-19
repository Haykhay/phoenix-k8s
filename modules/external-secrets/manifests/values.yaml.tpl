serviceAccount:
  create: true
  name: ${service_account_name}
%{ if length(sa_annotations) > 0 ~}
  annotations:
    ${indent(4, yamlencode(sa_annotations))}
%{ endif ~}

%{ if app_version != "" ~}
image:
  tag: "${app_version}"
%{ endif ~}
