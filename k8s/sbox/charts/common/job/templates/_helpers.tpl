{{/*
ref: https://github.com/helm/charts/blob/master/stable/postgresql/templates/_helpers.tpl
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "hmcts.releaseName" -}}
{{- if .Values.releaseNameOverride -}}
{{- .Values.releaseNameOverride | trunc 53 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 53 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hmcts.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{/*
Create meta data using releasename and chart name templates.
*/}}
{{- define "job.metadata" -}}
metadata:
  name: {{ include "hmcts.releaseName" . }}
  labels:
    app.kubernetes.io/name: {{ include "hmcts.releaseName" . }}
    helm.sh/chart: {{ include "hmcts.chart" . }}
    app.kubernetes.io/instance: {{ template "hmcts.releaseName" . }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Add labels to add to template spec.
*/}}
{{- define "job.labels" -}}
{{- if .Values.labels }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val }}
{{- end}}
{{- end}}
{{- end -}}