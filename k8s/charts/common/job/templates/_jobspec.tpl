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
         {{- $useKeyVaultpodidentity := .Values.keyVaults.usepodidentity }}
         {{- $aadIdentityName := .Values.aadIdentityName }}
        {{- range $key, $value := .Values.keyVaults }}
        - name: vault-{{ $key }}
          flexVolume:
            driver: "azure/kv"
            {{- if not $useKeyVaultpodidentity }}
            secretRef:
              name: {{ default "kvcreds" $value.secretRef }}
             {{- end }}
            options:
              usepodidentity: "{{ if $useKeyVaultpodidentity }}true{{ else }}false{{ end}}"
              tenantid: {{ $globals.tenantId }}
              keyvaultname: {{if $value.excludeEnvironmentSuffix }}{{ $key | quote }}{{else}}{{ printf "%s-%s" $key $globals.environment }}{{ end }}
              keyvaultobjectnames: {{ $value.secrets | join ";" | quote }}  #"some-username;some-password"
              keyvaultobjecttypes: {{ trimSuffix ";" (repeat (len $value.secrets) "secret;") | quote }} # OPTIONS: secret, key, cert
        {{- end }}
      {{- end }}
      securityContext:
        runAsUser: 1000
        fsGroup: 1000
      restartPolicy: {{ .Values.restartPolicy }}
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