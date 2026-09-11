{{/* Generate the chart name. */}}
{{- define "jenkins-nodejs-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "jenkins-nodejs-app.labels" -}}
helm.sh/chart: {{ include "jenkins-nodejs-app.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "jenkins-nodejs-app.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels. */}}
{{- define "jenkins-nodejs-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jenkins-nodejs-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}