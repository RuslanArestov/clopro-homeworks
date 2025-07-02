apiVersion: v1
kind: Config
clusters:
- name: yc-k8s
  cluster:
    server: https://${cluster_endpoint}
    certificate-authority-data: ${cluster_ca}
contexts:
- name: yc-context
  context:
    cluster: yc-k8s
    user: yc-user
current-context: yc-context
users:
- name: yc-user
  user:
    token: ${token}