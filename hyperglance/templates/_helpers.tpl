{{/*
Expand the name of the chart.
*/}}
{{- define "hyperglance.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hyperglance.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hyperglance.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hyperglance.labels" -}}
helm.sh/chart: {{ include "hyperglance.chart" . }}
{{ include "hyperglance.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hyperglance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hyperglance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hyperglance.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hyperglance.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Set image pull secrets if needed
*/}}
{{- define "imagePullSecret" }}
{{- with .Values.privateImageRepo }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}


{{/*
Append dev_configmap parameters to a ConfigMap if enabled is true and the parameter value isn't empty or ''
Params:
  - configmap: dictionary containing the configuration parameters
*/}}
{{- define "appendRuntimeParameters" -}}
{{- $configmap := .configmap -}}
{{- range $key, $value := $configmap -}}
{{- if and (ne $key "enabled") (or (and (not (eq $value "")) (not (eq $value "''")))) -}}
  {{ $key }}: '{{ $value }}'
{{- "\n" -}}
{{- end -}}
{{- end -}}
{{- end -}}
