# Single binary, objects under <bucket>/${tempo_prefix}/.
serviceAccount:
  create: true
  name: tempo
tempo:
  storage:
    trace:
      ${indent(6, yamlencode(tempo_storage))}
