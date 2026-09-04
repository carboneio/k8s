{{/*
Expand the name of the chart.
*/}}
{{- define "carbone-ee.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "carbone-ee.fullname" -}}
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
{{- define "carbone-ee.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "carbone-ee.labels" -}}
helm.sh/chart: {{ include "carbone-ee.chart" . }}
{{ include "carbone-ee.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "carbone-ee.selectorLabels" -}}
app.kubernetes.io/name: {{ include "carbone-ee.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "carbone-ee.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "carbone-ee.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Peer synchronization is active when template metadata has to be replicated across several pods.
Defined once so the StatefulSet, the NetworkPolicy and NOTES.txt cannot drift apart.
Returns a non-empty string when active, an empty one (falsy) otherwise.
*/}}
{{- define "carbone-ee.peerEnabled" -}}
{{- if and .Values.applicationConfiguration.templateManagement (or .Values.autoscaling.enabled (gt (int .Values.replicaCount) 1)) }}true{{- end }}
{{- end }}

{{/*
Port of the peer replication WebSocket. The NetworkPolicy must name the very same port as the
container, otherwise it would restrict nothing.
*/}}
{{- define "carbone-ee.peerPort" -}}
{{- .Values.applicationConfiguration.peerPort | default 5001 }}
{{- end }}
