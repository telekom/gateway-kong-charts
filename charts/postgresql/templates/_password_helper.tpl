# This is just a helper function for recursive regexp validation
# regexMatchList := (match first) && (regexMatchList rest)
{{- define "passutil.regexMatchList" -}}
  {{- if $.regex -}}
    {{- if regexMatch (first $.regex) $.value -}}
      {{ include "passutil.regexMatchList" (dict "regex" (rest $.regex) "value" $.value) }}
    {{- end -}}
  {{- else -}}
    {{- $.value -}}
  {{- end -}}
{{- end -}}

{{- define "passutil.matchPasswordRules" -}}
  {{- if $.rules.enabled -}}
    {{- $passwordLength := len $.password -}}
    {{- if ge $passwordLength ($.rules.length | int) -}}
      {{- include "passutil.regexMatchList" (dict "regex" $.rules.mustMatch "value" $.password) -}}
    {{- end -}}
  {{- else -}}
    {{- $.password -}}
  {{- end -}}
{{- end -}}

{{- define "passutil.validated" -}}
{{ include "passutil.matchPasswordRules" .  | required "Password does not match the password rules" }}
{{- end -}}
