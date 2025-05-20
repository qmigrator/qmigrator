{{/*
Expand the name of the chart.
*/}}
{{- define "qmig.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "qmig.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qmig.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qmig.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qmig.labels" -}}
helm.sh/chart: {{ include "qmig.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Define the qmig.namespace template if set with forceNamespace or .Release.Namespace is set
*/}}
{{- define "qmig.namespace" -}}
{{ printf "%s" .Release.Namespace }}
{{- end -}}

{{/*
Secret specification
*/}}
{{- define "qmig.secret" -}}
{{- printf "%s" .Values.secret.secretName | default  (printf "%s-secret" .Release.Name)  -}}
{{- end -}}

{{- define "qmig.secret.labels" -}}
{{ include "qmig.labels" . }}
{{- with .Values.secret.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{/*
Construct the name of the ServiceAccount.
*/}}
{{- define "qmig.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
{{- printf "%s" .Values.serviceAccount.name | default  (printf "%s-operator" .Release.Name) -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end -}}

{{- define "qmig.serviceAccount.labels" -}}
{{ include "qmig.labels" . }}
{{- with .Values.serviceAccount.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}


{{/*
All specification for Ingress
*/}}
{{- define "qmig.ingresscontroller.fullname" -}}
{{- printf "%s" .Values.ingressController.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.ingresscontroller.labels" -}}
{{ include "qmig.selectorLabels" . }}
component: {{ include "qmig.ingresscontroller.fullname" . | quote }}
{{- with .Values.ingressController.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.ingress.labels" -}}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.ingress.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}


{{/*
All specification for Gateways Controller
*/}}

{{- define "qmig.gateway.labels" -}}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.gateway.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.gateway.fullname" -}}
{{- printf "%s" .Values.gateway.name | default  (printf "%s-gateway" .Release.Name) -}}
{{- end -}}

{{- define "qmig.httpRoutes.labels" -}}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.httpRoutes.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.httpRoutes.fullname" -}}
{{- printf "%s" .Values.httpRoutes.name | default  (printf "%s-routes" .Release.Name) -}}
{{- end -}}


{{- define "qmig.httpRoutes.parentRefs" }}
- name: {{ include "qmig.gateway.fullname" . | quote }}
  namespace: {{ .Release.Namespace }}
  sectionName: http
{{- end }}

{{/*
All specification for app module
*/}}
{{- define "qmig.app.selectorLabels" -}}
component: {{ .Values.app.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.app.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.app.labels" -}}
{{ include "qmig.app.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.app.volumeMounts" }}
- mountPath: /tmp
  name: {{ .pvctemp }}
{{- end }}

{{- define "qmig.app.volume" }}
- name: {{ .pvctemp }}
  emptyDir: {}
{{- end }}


{{/*
All specification for eng module
*/}}
{{- define "qmig.eng.selectorLabels" -}}
component: {{ .Values.eng.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.eng.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.eng.labels" -}}
{{ include "qmig.eng.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.eng.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.eng.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.eng.hostname" -}}
{{- printf "http://" -}}{{- include "qmig.eng.fullname" . -}}.{{- printf "%s" .Release.Namespace -}}.svc.{{- printf "%s" .Values.clusterDomain -}}:8080
{{- end -}}

{{- define "qmig.eng.env" }}
- name: REDIS_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: REDIS_PASS
- name: PROJECT_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: PROJECT_NAME
- name: POSTGRES_HOST
  value: {{ include "qmig.db.hostname" . }}
- name: REDIS_HOST
  value: {{ include "qmig.msg.hostname" . }}
  {{- if .Values.airflow.enabled }}
- name: AIR_HOST
  value: {{ include "qmig.airflow.hostname" . }}
- name: airflow-password
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: airflow-password
  {{- end }}
- name: CRONJOB_PREFIX
  value: {{ .Release.Name }}
{{- end }}

{{- define "qmig.eng.volumeMounts" }}
- mountPath: /mnt/eng
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath | quote }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /mnt/extra
  subPath: {{ .Values.shared.folderPath.extraSubpath | quote}}
  name: {{ .pvcname }}
- mountPath: /mnt/dags
  subPath: {{  .Values.shared.folderPath.dagsSubpath | quote }}
  name: {{ .pvcname }}
- mountPath: /mnt/airflow/logs
  subPath: {{ .Values.shared.folderPath.logsSubpath | quote }}
  name: {{ .pvcname }}
- mountPath: /tmp
  name: {{ .pvctemp }}
{{- end }}

{{/*
All specification for db module
*/}}
{{- define "qmig.db.selectorLabels" -}}
component: {{ .Values.db.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.db.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.db.labels" -}}
{{ include "qmig.db.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.db.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.db.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.db.hostname" -}}
{{- if .Values.db.enabled -}}
{{- include "qmig.db.fullname" . -}}.{{- printf "%s" .Release.Namespace -}}.svc.{{- printf "%s" .Values.clusterDomain -}}
{{- else -}}
{{- printf "%s" .Values.db.dbConnection.hostname | required ".Values.db.dbConnection.hostname is required." -}}
{{- end -}}
{{- end -}}

{{- define "qmig.db.username" -}}
{{- printf "%s" .Values.db.dbConnection.username -}}
{{- end -}}

{{- define "qmig.db.password" -}}
{{- printf "%s" .Values.secret.data.POSTGRES_PASSWORD | required ".Values.secret.data.POSTGRES_PASSWORD is required."  -}}
{{- end -}}

{{- define "qmig.db.port" -}}
{{- printf "%s" .Values.db.dbConnection.port -}}
{{- end -}}

{{- define "qmig.db.env" -}}
- name: POSTGRES_PORT
  value: {{ (include "qmig.db.port" .) | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: POSTGRES_PASSWORD
- name: POSTGRES_DB
  value: {{- printf " prjdb%s" (.Values.secret.data.PROJECT_ID | toString) }}
- name: PGDATA
  value: "/var/lib/postgresql/data/pgdata"
- name: POSTGRES_USER
  value: {{ include "qmig.db.username" . }}
{{- end -}}


{{- define "qmig.db.volumeMounts" }}
- mountPath: /docker-entrypoint-initdb.d
  name: sqlconfig-sh
- mountPath: /var/lib/postgresql/data
  {{- if .Values.db.persistentVolume.subPath }}
  subPath: {{ .Values.db.persistentVolume.subPath | quote }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /var/run/postgresql
  name: {{ .pvctemp }}
- mountPath: /sqlconfig
  subPath: sqlfile
  name: {{ .pvctemp }}
{{- end }}


{{/*
Define an init-container which checks the DB status
*/}}
{{- define "qmig.db.load-db" }}
- name: load-db
  image: "{{ .Values.db.initContainer.loadDB.image.repository }}:{{ .Values.db.initContainer.loadDB.image.tag }}"
  resources:
    {{- toYaml .Values.db.initContainer.loadDB.resources | nindent 4 }}
  command: ['sh', '-c', "cp -f /app/*.sql /sqlconfig 2>/dev/null"]
  volumeMounts:
    - mountPath: /sqlconfig
      name: {{ .volumename }}
      subPath: sqlfile
{{- end }}


{{/*
Define an db-job as liquibase to apply db changes
*/}}
{{- define "qmig.dbJob.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.dbJob.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.dbJob.selectorLabels" -}}
component: {{ .Values.dbJob.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.dbJob.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.dbJob.labels" -}}
{{ include "qmig.dbJob.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.dbJob.image" -}}
{{- printf "%s:%s" (.Values.dbJob.image.repository ) (.Values.dbJob.image.tag) }}
{{- end -}}

{{- define "qmig.dbJob.waitForProjectDB.image" -}}
{{- printf "%s:%s" (.Values.dbJob.waitForProjectDB.image.repository ) (.Values.dbJob.waitForProjectDB.image.tag) }}
{{- end -}}

{{- define "qmig.dbJob.env" -}}
- name: LIQUIBASE_COMMAND_URL
  value: {{ urlJoin (dict "scheme" "jdbc:postgresql" "host" (printf "%s:%s" (include "qmig.db.hostname" .) (include "qmig.db.port" .)) "path" (printf "/prjdb%s" (.Values.secret.data.PROJECT_ID | toString) )) }}
- name: LIQUIBASE_COMMAND_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: POSTGRES_PASSWORD
- name: LIQUIBASE_COMMAND_USERNAME
  value: "postgres"
{{- end -}}

{{- define "qmig.dbJob.dbjob_command" }}
  - 'sh'
  - 'execute.sh'
{{- end }}

{{- define "qmig.dbJob.waitForProjectDB.wait-for-db-command" }}
  - sh'
  - '-c'
  - {{ printf "until nslookup %s; do echo waiting for database; sleep 2; done" (include "qmig.db.hostname" .) | quote }}
{{- end }}


{{/*
All specification for msg module
*/}}
{{- define "qmig.msg.selectorLabels" -}}
component: {{ .Values.msg.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.msg.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.msg.labels" -}}
{{ include "qmig.msg.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.msg.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.msg.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.msg.hostname" -}}
{{- include "qmig.msg.fullname" . -}}.{{- printf "%s" .Release.Namespace -}}.svc.{{- printf "%s" .Values.clusterDomain -}}
{{- end -}}

{{- define "qmig.msg.env" -}}
{{- if .Values.msg.auth.enabled }}
- name: REDIS_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: REDIS_PASS
{{- end }}
{{- end -}}

{{- define "qmig.project.env" -}}
- name: PROJECT_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: PROJECT_ID
- name: API_HOST
  value: {{ include "qmig.eng.hostname" . }}
{{- end -}}


{{/*
All specification for asses module
*/}}

{{- define "qmig.asses.name" -}}
{{- printf "%s" "asses" -}}
{{- end -}}

{{- define "qmig.asses.selectorLabels" -}}
component: {{ include "qmig.asses.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.asses.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.asses.labels" -}}
{{ include "qmig.asses.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.asses.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.asses.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.asses.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}


{{/*
All specification for convs module
*/}}

{{- define "qmig.convs.name" -}}
{{- printf "%s" "convs" -}}
{{- end -}}

{{- define "qmig.convs.selectorLabels" -}}
component: {{ include "qmig.convs.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.convs.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.convs.labels" -}}
{{ include "qmig.convs.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.convs.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.convs.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.convs.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}

{{/*
All specification for migrt module
*/}}

{{- define "qmig.migrt.name" -}}
{{- printf "%s" "migrt" -}}
{{- end -}}

{{- define "qmig.migrt.selectorLabels" -}}
component: {{ include "qmig.migrt.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.migrt.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.migrt.labels" -}}
{{ include "qmig.migrt.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.migrt.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.migrt.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.migrt.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /mnt/extra
  subPath: {{ .Values.shared.folderPath.extraSubpath | quote}}
  name: {{ .pvcname }}
- mountPath: /mnt/dags
  subPath: {{  .Values.shared.folderPath.dagsSubpath | quote }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}

{{/*
All specification for tests module
*/}}

{{- define "qmig.tests.name" -}}
{{- printf "%s" "tests" -}}
{{- end -}}

{{- define "qmig.tests.selectorLabels" -}}
component: {{ include "qmig.tests.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.tests.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.tests.labels" -}}
{{ include "qmig.tests.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.tests.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.tests.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.tests.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}



{{/*
All specification for perfs module
*/}}

{{- define "qmig.perfs.name" -}}
{{- printf "%s" "perfs" -}}
{{- end -}}

{{- define "qmig.perfs.selectorLabels" -}}
component: {{ include "qmig.perfs.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.perfs.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.perfs.labels" -}}
{{ include "qmig.perfs.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.perfs.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.perfs.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.perfs.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}



{{/*
All specification for deplo module
*/}}

{{- define "qmig.deplo.name" -}}
{{- printf "%s" "deplo" -}}
{{- end -}}

{{- define "qmig.deplo.selectorLabels" -}}
component: {{ include "qmig.deplo.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.deplo.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.deplo.labels" -}}
{{ include "qmig.deplo.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.deplo.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.deplo.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.deplo.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}



{{/*
All specification for wbdba module
*/}}

{{- define "qmig.wbdba.name" -}}
{{- printf "%s" "wbdba" -}}
{{- end -}}

{{- define "qmig.wbdba.selectorLabels" -}}
component: {{ include "qmig.wbdba.name" . }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.wbdba.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.wbdba.labels" -}}
{{ include "qmig.wbdba.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.wbdba.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "qmig.wbdba.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.wbdba.volumeMounts" }}
- mountPath: /mnt/pypod
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath }}
  {{- end }}
  name: {{ .pvcname }}
- mountPath: /app/tmp
  subPath: "tmp-e"
  name: {{ .pvctemp }}
- mountPath: /tmp
  subPath: "tmp"
  name: {{ .pvctemp }}
{{- end }}



{{/*
All specification for PVC
*/}}
{{- define "qmig.pv.shared" -}}
{{- printf "%s-%s" .Release.Name "shared" | quote | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.shared.labels" -}}
{{ include "qmig.labels" . }}
{{- with .Values.shared.persistentVolume.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{/*
All specification for PVC
*/}}
{{- define "qmig.shared.volume" }}
- name: {{ .pvcname }}
  {{- if .Values.shared.persistentVolume.enabled }}
  persistentVolumeClaim:
    claimName: {{ if .Values.shared.persistentVolume.existingClaim }}{{ .Values.shared.persistentVolume.existingClaim }}{{ else }}{{ .pvcname }}{{ end }}
  {{- else }}
  emptyDir: {}
  {{- end }}
- name: {{ .pvctemp }}
  emptyDir: {}
{{- end }}

{{/*
Docker credentails specification
*/}}
{{- define "qmig.dockerauth" -}}
{{- printf "%s" $.Values.imageCredentials.secretName | default  (printf "%s-docker" $.Release.Name) -}}
{{- end -}}

{{- define "qmig.dockerSecret" }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" (default "qmigrator.azurecr.io" .Values.imageCredentials.data.registry) .Values.imageCredentials.data.username .Values.imageCredentials.data.password (printf "%s:%s" .Values.imageCredentials.data.username .Values.imageCredentials.data.password | b64enc) | b64enc }}
{{- end }}

{{- define "qmig.dockerSecret.labels" -}}
{{ include "qmig.labels" . }}
{{- with .Values.imageCredentials.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.dockerauthList" -}}
  {{- $ := index . 0 -}}
  {{- $pullSecrets := list }}
  {{- if $.Values.imageCredentials.create }}
  {{- $pullSecrets = append $pullSecrets (include "qmig.dockerauth" $ ) -}}
  {{- end }}
  {{- with index . 1 }}
    {{- range .imagePullSecrets -}}
    {{- if kindIs "map" . -}}
      {{- $pullSecrets = append $pullSecrets .name -}}
    {{- else -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end }}
  {{- end -}}
  {{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
  {{- end -}}
{{- end -}}

{{/*
All specification for airflow
*/}}
{{- define "qmig.airflow.selectorLabels" -}}
main: {{ .Values.airflow.name | quote }}
{{ include "qmig.selectorLabels" . }}
{{- with .Values.airflow.labels }}
{{ toYaml . | print }}
{{- end }}
{{- end -}}

{{- define "qmig.airflow.labels" -}}
{{ include "qmig.airflow.selectorLabels" . }}
{{ include "qmig.labels" . }}
{{- end -}}

{{- define "qmig.airflow.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.airflow.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qmig.airflow.config" -}}
{{ include "qmig.airflow.fullname" . }}-config
{{- end -}}

{{- define "qmig.airflow.baseUrl" -}}
{{- printf "%s" (default "0.0.0.0" .Values.airflow.baseUrl) }}
{{- end -}}

{{- define "qmig.airflow.secret" -}}
{{- printf "%s" .Values.airflow.secret.secretName | default (printf "%s-air-secret" .Release.Name) -}}
{{- end -}}

{{- define "qmig.airflow.home" -}}
{{- printf "/opt/airflow" }}
{{- end -}}

{{- define "qmig.airflow.dags" -}}
{{- printf "%s/dags" (include "qmig.airflow.home" .) }}
{{- end -}}

{{- define "qmig.airflow.template" -}}
  {{- printf "%s/pod_templates" (include "qmig.airflow.home" .) }}
{{- end -}}

{{- define "qmig.airflow.image" -}}
{{- printf "%s:%s" (.Values.airflow.image.repository ) (.Values.airflow.image.tag) }}
{{- end -}}

{{- define "qmig.airflow.hostname" -}}
{{- printf "http://" -}}{{- include "qmig.airflow.fullname" . -}}-webserver.{{- printf "%s" .Release.Namespace -}}.svc.{{- printf "%s" .Values.clusterDomain -}}:8080
{{- end -}}

{{/* Standard Airflow environment variables */}}
{{- define "qmig.airflow.env" }}
- name: AIRFLOW__CORE__FERNET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: airflow-fernet-key
- name: AIRFLOW_HOME
  value: {{ include "qmig.airflow.home" . }}
- name: AIRFLOW__DATABASE__SQL_ALCHEMY_CONN
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: connection
- name: AIRFLOW_CONN_AIRFLOW_DB
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: connection
- name: AIRFLOW__WEBSERVER__SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: airflow-secret-key
- name: EXTRA_FOLDER
  value: '/opt/airflow/extra'
- name: MY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.airflow.secret" . }}
      key: airflow-password
{{- end -}}

{{- define "qmig.airflow.volumeMounts" }}
- name: {{ .pvctemp }}
  mountPath: /tmp
  subPath: "tmp"
- name: config
  mountPath: /opt/airflow/pod_templates/pod_template_file.yaml
  subPath: pod_template_file.yaml
- name: config
  mountPath: "/opt/airflow/airflow.cfg"
  subPath: airflow.cfg
- name: config
  mountPath: "/opt/airflow/config/airflow_local_settings.py"
  subPath: airflow_local_settings.py
- name: config
  mountPath: "/opt/airflow/webserver_config.py"
  subPath: webserver_config.py
- name: {{ .pvcname }}
  mountPath: "/opt/airflow/logs"
  subPath: {{ .Values.shared.folderPath.logsSubpath | quote }}
{{- end }}

{{- define "qmig.airflow.dataMounts" }}
{{- include "qmig.airflow.volumeMounts" (dict "Values" .Values "pvcname" .pvcname "pvctemp" .pvctemp )  }}
- name: {{ .pvcname }}
  mountPath: /opt/airflow/dags
  subPath: {{ .Values.shared.folderPath.dagsSubpath | quote }}
- name: {{ .pvcname }}
  mountPath: /opt/airflow/extra
  subPath: {{ .Values.shared.folderPath.extraSubpath | quote }}
{{- end }}

{{/*
All specification for PVC
*/}}
{{- define "qmig.airflow.volume" }}
- name: config
  configMap:
    name: {{ include "qmig.airflow.config" . }}
{{- end }}


{{- define "containerSecurityContext" -}}
  {{- $ := index . 0 -}}
  {{- with index . 1 }}
    {{- if .securityContexts.container -}}
      {{ toYaml .securityContexts.container | print }}
    {{- else -}}
      {}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "podSecurityContext" -}}
  {{- $ := index . 0 -}}
  {{- with index . 1 }}
    {{- if .securityContexts.pod -}}
      {{ toYaml .securityContexts.pod | print }}
    {{- else -}}
      {}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "airflow.containerSecurityContext" -}}
  {{- $ := index . 0 -}}
  {{- with index . 1 }}
    {{- if .securityContexts.container -}}
      {{ toYaml .securityContexts.container | print }}
    {{- else if $.Values.airflow.securityContexts.container -}}
      {{ toYaml $.Values.airflow.securityContexts.container | print }}
    {{- else -}}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "airflow.podSecurityContext" -}}
  {{- $ := index . 0 -}}
  {{- with index . 1 }}
    {{- if .securityContexts.pod -}}
      {{ toYaml .securityContexts.pod | print }}
    {{- else if $.Values.airflow.securityContexts.pod -}}
      {{ toYaml $.Values.airflow.securityContexts.pod | print }}
    {{- else -}}
runAsUser: {{ $.Values.airflow.uid }}
fsGroup: {{ $.Values.airflow.gid }}
    {{- end }}
  {{- end }}
{{- end }}


{{- define "qmig.airflow.scheduler_liveness_check_command" }}
  - sh
  - -c
  - |
    CONNECTION_CHECK_MAX_COUNT=0 AIRFLOW__LOGGING__LOGGING_LEVEL=ERROR exec /entrypoint \
    airflow jobs check --job-type SchedulerJob --local
{{- end }}

{{- define  "qmig.airflow.scheduler_startup_check_command" }}
  - sh
  - -c
  - |
    CONNECTION_CHECK_MAX_COUNT=0 AIRFLOW__LOGGING__LOGGING_LEVEL=ERROR exec /entrypoint \
    airflow jobs check --job-type SchedulerJob --local
{{- end }}

{{- define  "qmig.airflow.create_userjob_args" }}
  - bash
  - /opt/airflow/access.sh
{{- end }}

{{- define  "qmig.airflow.migration_job_args" }}
  - "bash"
  - "-c"
  - >-
    exec airflow db migrate
{{- end }}

{{- define "qmig.airflow.wait-for-migrations-command" }}
  - airflow
  - db
  - check-migrations
  - --migration-wait-timeout={{ .Values.airflow.waitForMigrations.migrationsWaitTimeout | default 60 }}
{{- end }}