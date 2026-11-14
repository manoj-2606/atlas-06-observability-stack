{{/*
Common labels applied to all resources
*/}}
{{- define "atlas-platform.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
team: {{ .Values.labels.team | default "platform" }}
cost-center: {{ .Values.labels.cost-center | default "atlas-learning" }}
{{- end -}}

{{/*
Selector labels (subset — used in matchLabels)
*/}}
{{- define "atlas-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Fullname — used for resource naming
*/}}
{{- define "atlas-platform.fullname" -}}
{{ .Release.Name }}
{{- end -}}