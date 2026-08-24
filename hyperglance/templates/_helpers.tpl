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
Build a .dockerconfigjson value for a single registry.
Call with a repo dict as the context, e.g. {{ include "imagePullSecret" .Values.privateImageRepo }}
or, inside a range over privateImageRepos, {{ include "imagePullSecret" $repo }}.
*/}}
{{- define "imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}

{{/*
Emit the imagePullSecrets list entries for every enabled private registry.
Processes the additional privateImageRepos map AND the legacy singular privateImageRepo
(additive — both are honoured). Used by every pod spec so the logic lives in one place.
*/}}
{{- define "hyperglance.imagePullSecrets" -}}
{{- range $name, $repo := .Values.privateImageRepos }}
{{- if $repo.enabled }}
{{- if not (and (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name) (le (len $name) 40)) }}
{{- fail (printf "privateImageRepos key %q must be a DNS-1123 label (lowercase alphanumeric or '-', starting and ending alphanumeric) and at most 40 characters - it becomes part of the Secret name %s" $name (printf "%s-repo-secret-%s" $.Release.Name $name)) }}
{{- end }}
- name: {{ $repo.existingSecretName | default (printf "%s-repo-secret-%s" $.Release.Name $name) }}
{{- end }}
{{- end }}
{{- if .Values.privateImageRepo.enabled }}
- name: {{ .Values.privateImageRepo.existingSecretName | default (printf "%s-repo-secret" .Release.Name) }}
{{- end }}
{{- end -}}


{{/*
Resolve the llama api-key Secret name + key. Bring-your-own via ai.llama.existingSecretName,
otherwise the chart-created "<release>-llama-api-key". Both the llama pod and httpd read
this so they share one source of truth.
*/}}
{{- define "hyperglance.llamaApiKeySecretName" -}}
{{- .Values.ai.llama.existingSecretName | default (printf "%s-llama-api-key" .Release.Name) -}}
{{- end -}}

{{/*
Single source of truth for the llama API sub-path prefix. Consumed by the llama pod
(--api-prefix), httpd (LLAMA_PROXY_PREFIX via the ConfigMap) and the health probe path,
so all three can never drift.
*/}}
{{- define "hyperglance.llamaApiPrefix" -}}
{{- .Values.ai.llama.webui.path | default "/llama" -}}
{{- end -}}
{{- define "hyperglance.llamaApiKeySecretKey" -}}
{{- .Values.ai.llama.existingSecretKey | default "LLAMA_API_KEY" -}}
{{- end -}}

{{/*
Append dev_configmap parameters to a ConfigMap if enabled is true and the parameter value isn't empty or ''
Params:
  - configmap: dictionary containing the configuration parameters
*/}}
{{- define "appendRuntimeParameters" -}}
{{- if .enabled -}}
{{- $configmap := .configmap -}}
{{- range $key, $value := $configmap -}}
{{- if and (ne $key "enabled") (or (and (not (eq $value "")) (not (eq $value "''")))) -}}
  {{ $key }}: '{{ $value }}'
{{- "\n" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
