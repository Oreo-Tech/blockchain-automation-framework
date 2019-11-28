apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  annotations:
    flux.weave.works/automated: "false"
  namespace: {{ component_ns }}
spec:
  releaseName: {{ component_name }}
  chart:
    path: {{ org.gitops.chart_source }}/nms
    git: {{ org.gitops.git_ssh }}
    ref: {{ org.gitops.branch }}
  values:
    nodeName: {{ component_name }}
    metadata:
      namespace: {{ component_ns }}
    image:
      authusername: sa
      containerName: {{ network.docker.url }}/networkmap-linuxkit:latest
      env:
      - name: NETWORKMAP_PORT
        value: 8080
      - name: NETWORKMAP_ROOT_CA_NAME
        value: {{ services.nms.subject }}
      - name: NETWORKMAP_TLS
        value: false
      - name: NETWORKMAP_DB
        value: /opt/networkmap/db
      - name: DB_USERNAME
        value: {{ component_name }}
      - name: NETWORKMAP_AUTH_USERNAME
        value: sa
      - name: DB_URL
        value: mongodb-{{ component_name }}
      - name: DB_PORT
        value: 27017
      - name: DATABASE
        value: admin
      - name: NETWORKMAP_CACHE_TIMEOUT
        value: 60S
      - name: NETWORKMAP_MONGOD_DATABASE
        value: networkmap
      imagePullSecret: regcred
      initContainerName: {{ network.docker.url }}/alpine-utils:1.0
      mountPath:
          basePath: /opt/networkmap
    storage:
      memory: 512Mi
      mountPath: "/opt/h2-data"
      name: {{ org.cloud_provider }}storageclass
    vault:
      address: {{ vault.url }}
      role: vault-role
      authpath: {{ component_auth }}
      serviceaccountname: vault-auth
      secretprefix: {{ component_name }}
      certsecretprefix: {{ component_name }}/certs
      dbcredsecretprefix: {{ component_name }}/credentials/mongodb
      secretnetworkmappass: {{ component_name }}/credentials/userpassword
    healthcheck:
      readinesscheckinterval: 10
      readinessthreshold: 15
      dburl: mongodb-{{ component_name }}:27017
    service:
      port: {{ services.nms.ports.servicePort }}
      targetPort: {{ services.nms.ports.targetPort }}
      type: ClusterIP
      annotations: {}
    deployment:
      annotations: {}
    pvc:
      annotations: {}
    ambassador:
      annotations: |- 
        ---
        apiVersion: ambassador/v1
        kind: Mapping
        name: {{ component_name }}_mapping
        prefix: /
        service: {{ component_name }}.{{ component_ns }}:{{ services.nms.ports.servicePort }}
        host: {{ component_name }}.{{ item.external_url_suffix }}:8443
        tls: false
        ---
        apiVersion: ambassador/v1
        kind: TLSContext
        name: {{ component_name }}_mapping_tlscontext
        hosts:
        - {{ component_name }}.{{ item.external_url_suffix }}
        secret: {{ component_name }}-ambassador-certs 
        