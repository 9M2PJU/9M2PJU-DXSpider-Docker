{{/*
Expand the name of the chart.
*/}}
{{- define "dxspider.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dxspider.fullname" -}}
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
{{- define "dxspider.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dxspider.labels" -}}
helm.sh/chart: {{ include "dxspider.chart" . }}
{{ include "dxspider.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dxspider.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dxspider.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dxspider.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dxspider.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "dxspider.image" -}}
{{- $registryName := .Values.image.repository }}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" $registryName $tag }}
{{- end }}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "dxspider.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the cluster callsign in uppercase
*/}}
{{- define "dxspider.callsign" -}}
{{- .Values.cluster.callsign | upper }}
{{- end }}

{{/*
Return the sysop callsign in uppercase
*/}}
{{- define "dxspider.sysopCallsign" -}}
{{- .Values.sysop.callsign | upper }}
{{- end }}

{{/*
Return the locator in uppercase
*/}}
{{- define "dxspider.locator" -}}
{{- .Values.cluster.location.locator | upper }}
{{- end }}

{{/*
Return the database DSN
*/}}
{{- define "dxspider.databaseDSN" -}}
{{- if .Values.database.enabled }}
{{- printf "dbi:%s:%s:%s:%d" .Values.database.type .Values.database.name .Values.database.hostname (.Values.database.port | int) }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Return the PVC name
*/}}
{{- define "dxspider.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "data-%s-0" (include "dxspider.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return true if a secret object should be created
*/}}
{{- define "dxspider.createSecret" -}}
{{- if or .Values.sysop.password .Values.database.password }}
{{- true }}
{{- end }}
{{- end }}

{{/*
Return the secret name
*/}}
{{- define "dxspider.secretName" -}}
{{- printf "%s-secret" (include "dxspider.fullname" .) }}
{{- end }}

{{/*
Return the configmap name
*/}}
{{- define "dxspider.configMapName" -}}
{{- printf "%s-config" (include "dxspider.fullname" .) }}
{{- end }}

{{/*
Validate values
*/}}
{{- define "dxspider.validateValues" -}}
{{- if not .Values.cluster.callsign }}
{{- fail "cluster.callsign is required" }}
{{- end }}
{{- if not .Values.sysop.callsign }}
{{- fail "sysop.callsign is required" }}
{{- end }}
{{- if not .Values.cluster.location.locator }}
{{- fail "cluster.location.locator is required" }}
{{- end }}
{{- end }}

{{/*
Return the telnet service port name
*/}}
{{- define "dxspider.telnetPortName" -}}
{{- "telnet" }}
{{- end }}

{{/*
Return the console service port name
*/}}
{{- define "dxspider.consolePortName" -}}
{{- "console" }}
{{- end }}

{{/*
Return the metrics service port name
*/}}
{{- define "dxspider.metricsPortName" -}}
{{- "metrics" }}
{{- end }}

{{/*
Render a value that contains template.
Usage:
{{ include "dxspider.tplValue" (dict "value" .Values.path.to.value "context" $) }}
*/}}
{{- define "dxspider.tplValue" -}}
{{- if typeIs "string" .value }}
  {{- tpl .value .context }}
{{- else }}
  {{- tpl (.value | toYaml) .context }}
{{- end }}
{{- end }}

{{/*
Generate random password if not provided
*/}}
{{- define "dxspider.generatePassword" -}}
{{- if .Values.sysop.password }}
{{- .Values.sysop.password }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "dxspider.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion }}
{{- print "networking.k8s.io/v1" }}
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for StatefulSet
*/}}
{{- define "dxspider.statefulset.apiVersion" -}}
{{- print "apps/v1" }}
{{- end }}

{{/*
Compile all warnings into a single message
*/}}
{{- define "dxspider.validateValues.warnings" -}}
{{- $warnings := list }}
{{- if not .Values.persistence.enabled }}
{{- $warnings = append $warnings "WARNING: Persistence is disabled. All data will be lost on pod restart!" }}
{{- end }}
{{- if and .Values.database.enabled (not .Values.database.password) }}
{{- $warnings = append $warnings "WARNING: Database is enabled but no password is set!" }}
{{- end }}
{{- if and .Values.ingress.enabled (not .Values.ingress.tls) }}
{{- $warnings = append $warnings "WARNING: Ingress is enabled but TLS is not configured!" }}
{{- end }}
{{- if $warnings }}
{{- printf "\n%s" (join "\n" $warnings) }}
{{- end }}
{{- end }}
