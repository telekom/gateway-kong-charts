<!--
Sync Impact Report:
Version: 1.0.0 (Initial Constitution)
Ratified: 2025-10-10
Last Amended: 2025-10-10

Modified Principles: N/A (Initial version)
Added Sections: All (Initial version)
Removed Sections: None

Templates Status:
✅ plan-template.md - Aligned with Constitution Check section
✅ spec-template.md - Aligned with requirements and testing principles
✅ tasks-template.md - Aligned with incremental delivery and testing principles

Follow-up TODOs: None
-->

# Gateway Kong Charts Constitution

## Core Principles

### I. Values-First Configuration

**MUST**: All chart configuration MUST be exposed through `values.yaml` with sensible defaults.

**MUST**: Every configurable parameter MUST have:
- Clear documentation in the values file with inline comments
- A sensible default that works for common use cases
- Type-safe validation where applicable

**MUST**: Configuration structure MUST be hierarchical and intuitive, grouping related settings under logical parent keys (e.g., `proxy.ingress.*`, `adminApi.tls.*`).

**MUST NOT**: Hardcode values in templates that users might reasonably want to customize.

**Rationale**: Helm charts are consumed through values files. Making configuration discoverable, documented, and predictable reduces cognitive load and prevents deployment errors.

### II. Template Simplicity and Readability

**MUST**: Templates MUST be readable by operators who are not Go template experts.

**MUST**: Complex logic MUST be extracted to named templates (using `{{- define }}`) with clear names that describe their purpose.

**MUST**: Template files MUST follow single responsibility - one Kubernetes resource type per file (e.g., `deployment-kong.yml`, `service-proxy.yml`).

**MUST**: Use `{{- include }}` for reusable template fragments rather than duplicating logic.

**SHOULD**: Limit template nesting depth to 3 levels maximum. Deeper nesting MUST be refactored into named templates.

**MUST NOT**: Use obscure Go template features without inline comments explaining their purpose.

**Rationale**: Templates are read far more often than written. Operators need to understand what will be deployed. Simple, well-organized templates reduce debugging time and deployment errors.

### III. Backward Compatibility and Versioning

**MUST**: Chart version MUST follow semantic versioning (MAJOR.MINOR.PATCH).

**MUST**: Breaking changes (requiring user action) MUST increment MAJOR version.

**MUST**: New features or significant enhancements MUST increment MINOR version.

**MUST**: Bug fixes and minor improvements MUST increment PATCH version.

**MUST**: Breaking changes MUST be documented in `CHANGELOG.md` with:
- Clear description of what changed
- Migration path from previous version
- Example of old vs. new configuration

**MUST**: Deprecated features MUST be marked in values file comments and supported for at least one MINOR version before removal.

**SHOULD**: Use `fail` template function to provide helpful error messages when deprecated values are used.

**Rationale**: Helm charts are infrastructure code. Breaking user deployments without warning erodes trust. Clear versioning and migration paths enable safe upgrades.

### IV. Platform Portability and Extensibility

**MUST**: Chart MUST work on standard Kubernetes without platform-specific assumptions.

**MUST**: Platform-specific configurations (e.g., CaaS, AWS) MUST be isolated in `platforms/*.yaml` files.

**MUST**: Platform-specific values MUST be overlays that extend base values, not replacements.

**MUST**: New platform support MUST be addable without modifying core templates.

**SHOULD**: Use Kubernetes standard resource definitions. Platform-specific resources (e.g., OpenShift Routes) MUST be optional and disabled by default.

**MUST**: Security contexts, storage classes, and networking configurations MUST be overridable per platform.

**Rationale**: Organizations deploy to multiple platforms. Platform-specific code in core templates creates maintenance burden and fragility. Isolation enables extensibility without complexity.

### V. Progressive Disclosure and Sensible Defaults

**MUST**: Default `values.yaml` MUST enable a working deployment with minimal user input.

**MUST**: Advanced features MUST be disabled by default with clear documentation on how to enable them.

**MUST**: Required user inputs (e.g., passwords, hostnames) MUST use placeholder values like `"changeme"` with validation that fails on deployment if not changed.

**MUST**: Feature flags MUST use boolean `enabled` keys (e.g., `autoscaling.enabled`, `jumper.enabled`).

**SHOULD**: Group advanced configuration under clearly named sections (e.g., `advanced.*`, `experimental.*`).

**MUST NOT**: Require users to understand the entire values file to deploy successfully.

**Rationale**: Users should be able to deploy quickly with defaults, then progressively customize. Overwhelming users with options upfront increases error rates and time-to-value.

### VI. Observability and Debuggability

**MUST**: All deployments MUST include:
- Liveness, readiness, and startup probes with sensible defaults
- Structured logging to stdout/stderr (configurable format: json or text)
- Prometheus metrics endpoints (if monitoring is enabled)

**MUST**: Health check endpoints MUST be documented in values file comments.

**MUST**: Resource limits and requests MUST have sensible defaults based on component requirements.

**SHOULD**: Include annotations for common monitoring tools (e.g., Prometheus scraping).

**MUST**: Deployment failures MUST provide actionable error messages using `fail` or `required` template functions.

**MUST NOT**: Silently ignore configuration errors. Fail fast with clear messages.

**Rationale**: Production systems require observability. Operators need to understand system health and debug issues quickly. Failing fast with clear errors prevents silent misconfigurations.

### VII. Security by Default

**MUST**: Security-sensitive defaults MUST be secure (e.g., TLS enabled, restrictive security contexts).

**MUST**: Secrets MUST never be hardcoded in templates or committed to version control.

**MUST**: Passwords and sensitive values MUST use Kubernetes Secrets, not ConfigMaps.

**MUST**: Security contexts MUST follow least-privilege principle (non-root user, read-only root filesystem where possible).

**MUST**: TLS configuration MUST support modern TLS versions only (TLSv1.2+) by default.

**SHOULD**: Provide clear documentation on how to supply custom certificates and secrets.

**MUST NOT**: Disable security features by default for convenience.

**Rationale**: Security breaches are costly. Secure defaults protect users who may not be security experts. Making insecure configurations opt-in forces conscious decisions.

## Helm Best Practices Compliance

**MUST**: Follow official Helm best practices documented at https://helm.sh/docs/chart_best_practices/

**MUST**: Use `_helpers.tpl` for:
- Chart name and fullname generation
- Label selectors and common labels
- Service account name resolution

**MUST**: Include standard Kubernetes labels:
```yaml
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "chart.chart" . }}
```

**MUST**: Use `lookup` function cautiously - it breaks `helm template` and `--dry-run` modes.

**MUST**: Validate required values using `required` function with helpful error messages.

**SHOULD**: Include `NOTES.txt` with post-installation instructions and helpful commands.

## Testing and Validation Requirements

**MUST**: All chart changes MUST be validated with:
- `helm lint` (no errors)
- `helm template` (renders without errors)
- Deployment to test cluster (successful rollout)

**SHOULD**: Include unit tests using `helm unittest` plugin for complex template logic.

**SHOULD**: Test platform-specific configurations in their target environments.

**MUST**: Breaking changes MUST include upgrade testing from previous version.

**Rationale**: Helm charts are declarative infrastructure. Broken charts cause production outages. Automated validation catches errors before deployment.

## Documentation Standards

**MUST**: `README.md` MUST include:
- Quick start guide with minimal configuration
- Complete values documentation (auto-generated from values.yaml using helm-docs)
- Upgrade guides for breaking changes
- Troubleshooting section for common issues

**MUST**: `values.yaml` MUST include inline comments for every configurable parameter.

**MUST**: `CHANGELOG.md` MUST document all changes per version with:
- Breaking changes clearly marked
- New features
- Bug fixes
- Deprecations

**IMPORTANT**: `CHANGELOG.md` is automatically generated by the semantic-release bot. Do NOT manually edit this file. Changes will be generated from commit messages following conventional commit format.

**SHOULD**: Include architecture diagrams for complex deployments.

**MUST**: Update documentation in the same PR as code changes.

**Rationale**: Documentation is the user interface of the chart. Outdated or missing documentation leads to support burden and deployment errors.

## Governance

This constitution supersedes all other development practices for the Gateway Kong Charts project.

**Amendment Process**:
1. Proposed changes MUST be documented in a pull request with rationale
2. Changes MUST be reviewed by project maintainers
3. Breaking principle changes require MAJOR version bump of constitution
4. All dependent templates and documentation MUST be updated in the same change

**Compliance**:
- All pull requests MUST verify compliance with these principles
- Complexity violations MUST be explicitly justified in PR description
- Reviewers MUST check for principle adherence
- Automated checks (linting, testing) MUST enforce technical requirements

**Conflict Resolution**:
- When principles conflict, security takes precedence
- When in doubt, favor simplicity over features
- User experience and ease of understanding trump implementation convenience

**Version**: 1.0.0 | **Ratified**: 2025-10-10 | **Last Amended**: 2025-10-10