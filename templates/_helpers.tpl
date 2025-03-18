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
{{- printf "%s" .Values.secret.secretName | default  (printf "%s-admin-secret" .Release.Name)  -}}
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
{{- printf "%s" .Values.gateway.name | default  (printf "%s-admin-gateway" .Release.Name) -}}
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
- name: PROJECT_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "qmig.secret" . }}
      key: PROJECT_NAME
- name: POSTGRES_HOST
  value: {{ include "qmig.db.hostname" . }}
{{- end }}

{{- define "qmig.eng.volumeMounts" }}
- mountPath: /mnt/eng
  {{- if .Values.shared.persistentVolume.subPath }}
  subPath: {{ .Values.shared.persistentVolume.subPath | quote }}
  {{- end }}
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
  value: {{- printf " admindb%s" (.Values.secret.data.PROJECT_ID | toString) }}
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
EXAMPLE USAGE: {{ include "airflow.init_container.check_db" (dict "Release" .Release "Values" .Values "volumeMounts" $volumeMounts) }}
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
{{- printf "%s" $.Values.imageCredentials.secretName | default  (printf "%s-admin-docker" $.Release.Name) -}}
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