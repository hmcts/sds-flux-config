{{/*
Create job spec.
*/}}
{{- define "job.spec" -}}
spec:
  {{- if .Values.backoffLimit }}
  backoffLimit: {{ .Values.backoffLimit }}
  {{- end }}
  {{- if .Values.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ .Values.activeDeadlineSeconds }}
  {{- end }}
  {{- if .Values.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ .Values.ttlSecondsAfterFinished }}
  {{- end }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "hmcts.releaseName" . }}
        {{- include "job.labels" . | indent 8}}
        {{- if .Values.aadIdentityName }}
        aadpodidbinding: {{ .Values.aadIdentityName }}
        {{- end }}
    spec:
      {{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
      volumes:
        {{- $globals := .Values.global }}
        {{- $releaseName := include "hmcts.releaseName" . }}
        {{- range $key, $value := .Values.keyVaults }}
        - name: vault-{{ $key }}
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "{{ $releaseName }}-vault-secret-provider"
        {{- end }}
      {{- end }}
      securityContext:
        runAsUser: 1000
        fsGroup: 1000
      restartPolicy: {{ .Values.restartPolicy }}
      {{- if .Values.global.affinity }}
      affinity:
{{ toYaml .Values.global.affinity | indent 8 }}
      {{- end }}
      containers:
      - image: {{ .Values.image }}
        name: {{ include "hmcts.releaseName" . }}
        securityContext:
          allowPrivilegeEscalation: false
        env:
          {{- if .Values.secrets -}}
              {{- range $key, $val := .Values.secrets }}
                {{- if and $val (not $val.disabled) }}
        - name: {{ if $key | regexMatch "^[^.-]+$" -}}
                  {{- $key }}
                {{- else -}}
                    {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
                {{- end }}
          valueFrom:
            secretKeyRef:
              name: {{  tpl (required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef) $ }}
              key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
                {{- end }}
              {{- end }}
          {{- end -}}
          {{- if .Values.environment -}}
              {{- range $key, $val := .Values.environment }}
        - name: {{ if $key | regexMatch "^[^.-]+$" -}}
                  {{- $key }}
                {{- else -}}
                    {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
                {{- end }}
          value: {{ tpl ($val | quote) $ }}
            {{- end }}
         {{- end }}

        {{- if .Values.configmap }}
        envFrom:
          - configMapRef:
              name: {{ include "hmcts.releaseName" . }}
        {{- end }}

        {{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
        volumeMounts:
          {{- range $key, $value := .Values.keyVaults }}
          - name: vault-{{ $key }}
            mountPath: /mnt/secrets/{{ $key }}
            readOnly: true
          {{- end }}
        {{- end }}

        resources:
          requests:
            memory: {{ .Values.memoryRequests }}
            cpu: {{ .Values.cpuRequests }}
          limits:
            memory: {{ .Values.memoryLimits }}
            cpu: {{ .Values.cpuLimits }}
        imagePullPolicy: IfNotPresent
{{- end -}}