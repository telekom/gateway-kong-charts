---
description: "Implementation tasks for KEDA-based autoscaling feature"
---

# Tasks: KEDA-Based Autoscaling for Gateway

**Input**: Design documents from `/specs/001-adding-keda-i/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: This feature does not require test tasks as it's a Helm chart configuration feature. Validation is done through helm lint, helm template, and manual deployment testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Helm chart root: `~/dev/tardis/gateway-kong-charts/`
- Templates: `templates/`
- Documentation: `README.md`, `CHANGELOG.md`
- Specs: `specs/001-adding-keda-i/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and version management

- [X] T001 Create feature branch `001-adding-keda-i` from main
- [X] T002 Update Chart.yaml version (MINOR bump) and add feature description in Chart.yaml
- [X] T003 [P] Create backup of existing values.yaml for reference

**Checkpoint**: Branch and versioning ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core configuration structure and validation that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Add complete `kedaAutoscaling` section to values.yaml with all configuration options per data-model.md
- [X] T005 Add inline documentation comments for all kedaAutoscaling configuration fields in values.yaml
- [X] T006 [P] Create validation logic in templates/_kong.tpl for mutual exclusion of HPA and KEDA (fail if both enabled)
- [X] T007 [P] Create validation logic in templates/_kong.tpl for minReplicas <= maxReplicas
- [X] T008 [P] Create validation logic in templates/_kong.tpl for required Prometheus serverAddress when prometheus trigger enabled
- [X] T009 Update templates/deployment-kong.yml to exclude replicas field when kedaAutoscaling.enabled is true (similar to existing autoscaling logic)
- [X] T010 Update templates/horizontal-pod-autoscaler.yaml condition to: `{{- if and .Values.autoscaling.enabled (not .Values.kedaAutoscaling.enabled) -}}`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Metric-Based Autoscaling (Priority: P1) 🎯 MVP

**Goal**: Enable automatic scaling based on CPU and memory metrics to maintain performance during peak times while reducing costs during low-traffic periods

**Independent Test**: Deploy gateway with metric-based autoscaling enabled for both CPU and memory thresholds. Generate increasing traffic load and observe pod count increasing when either CPU or memory thresholds are exceeded. Reduce traffic and observe pod count decreasing after cooldown period.

### Implementation for User Story 1

- [X] T011 [US1] Create templates/scaled-object-keda.yaml with conditional rendering based on kedaAutoscaling.enabled
- [X] T012 [US1] Add metadata section to templates/scaled-object-keda.yaml using kong.labels helper and autoscaling component label
- [X] T013 [US1] Add scaleTargetRef section in templates/scaled-object-keda.yaml pointing to deployment
- [X] T014 [US1] Add minReplicaCount and maxReplicaCount configuration in templates/scaled-object-keda.yaml from values
- [X] T015 [US1] Add pollingInterval and cooldownPeriod configuration in templates/scaled-object-keda.yaml from values
- [X] T016 [US1] Add fallback configuration section in templates/scaled-object-keda.yaml (conditional on fallback.enabled)
- [X] T017 [US1] Add advanced.horizontalPodAutoscalerConfig section in templates/scaled-object-keda.yaml (conditional on advanced config)
- [X] T018 [US1] Implement CPU trigger in templates/scaled-object-keda.yaml triggers section (conditional on triggers.cpu.enabled)
- [X] T019 [US1] Implement memory trigger in templates/scaled-object-keda.yaml triggers section (conditional on triggers.memory.enabled)
- [X] T020 [US1] Implement Prometheus/Victoria Metrics trigger in templates/scaled-object-keda.yaml with query templating support (conditional on triggers.prometheus.enabled)
- [X] T021 [US1] Add authenticationRef section for Prometheus trigger using ClusterTriggerAuthentication reference
- [X] T022 [US1] Test helm template rendering with CPU and memory triggers enabled
- [X] T023 [US1] Test helm lint passes with metric-based configuration

**Checkpoint**: At this point, User Story 1 should be fully functional - metric-based autoscaling works independently with CPU and memory triggers

---

## Phase 4: User Story 2 - Schedule-Based Scaling (Priority: P2)

**Goal**: Enable time-based scaling to proactively handle known traffic patterns, ensuring capacity is available before predictable load increases occur

**Independent Test**: Configure schedule-based scaling with specific time windows. Verify gateway scales up at the scheduled time before traffic arrives. Verify gateway scales down at the scheduled off-peak time. Confirm this works independently of metric-based scaling.

### Implementation for User Story 2

- [X] T024 [US2] Implement cron trigger loop in templates/scaled-object-keda.yaml (conditional on triggers.cron.enabled)
- [X] T025 [US2] Add timezone configuration for cron triggers in templates/scaled-object-keda.yaml with Europe/Berlin default
- [X] T026 [US2] Add start, end, and desiredReplicas fields for each cron schedule in templates/scaled-object-keda.yaml
- [X] T027 [US2] Add optional name field for cron schedules in templates/scaled-object-keda.yaml
- [X] T028 [US2] Test helm template rendering with multiple cron schedules configured
- [X] T029 [US2] Test helm lint passes with schedule-based configuration
- [X] T030 [US2] Verify cron and metric triggers can coexist in rendered template

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - schedule-based scaling works with or without metric-based scaling

---

## Phase 5: User Story 3 - Anti-Flapping Protection (Priority: P3)

**Goal**: Prevent rapid scale-up and scale-down cycles through cooldown periods and stabilization windows to maintain gateway stability

**Independent Test**: Create oscillating traffic patterns that cross the scaling threshold repeatedly. Verify that scaling decisions are dampened by cooldown periods and stabilization windows. Confirm pods aren't created and destroyed in rapid succession.

### Implementation for User Story 3

- [X] T031 [US3] Verify cooldownPeriod configuration is properly applied in templates/scaled-object-keda.yaml (already implemented in T015)
- [X] T032 [US3] Verify stabilizationWindowSeconds for scaleDown is properly applied in templates/scaled-object-keda.yaml (already implemented in T017)
- [X] T033 [US3] Verify stabilizationWindowSeconds for scaleUp is properly applied in templates/scaled-object-keda.yaml (already implemented in T017)
- [X] T034 [US3] Verify scale-down policies (Percent type) are properly applied in templates/scaled-object-keda.yaml (already implemented in T017)
- [X] T035 [US3] Verify scale-up policies (Percent and Pods types) are properly applied in templates/scaled-object-keda.yaml (already implemented in T017)
- [X] T036 [US3] Test helm template rendering with conservative anti-flapping configuration
- [X] T037 [US3] Test helm template rendering with aggressive anti-flapping configuration
- [X] T038 [US3] Document anti-flapping tuning guidelines in quickstart.md

**Checkpoint**: All user stories should now be independently functional - anti-flapping protection is properly configured

---

## Phase 6: Documentation & Polish

**Purpose**: Complete documentation and final validation

- [X] T039 [P] Add KEDA autoscaling section to README.md with prerequisites and basic usage
- [X] T040 [P] Add detailed configuration examples to README.md (minimal, full, production)
- [X] T041 [P] Document migration from HPA to KEDA in README.md
- [X] T042 [P] ~~Add KEDA feature entry to CHANGELOG.md~~ (N/A - CHANGELOG.md is auto-generated by semantic-release bot)
- [X] T043 [P] Update quickstart.md with troubleshooting section for common KEDA issues
- [X] T044 [P] Add validation commands section to quickstart.md (kubectl get scaledobject, describe, etc.)
- [X] T045 [P] Document ClusterTriggerAuthentication setup requirements in quickstart.md
- [X] T046 Perform final helm lint validation on complete chart
- [X] T047 Perform helm template validation with all trigger combinations
- [X] T048 Test backward compatibility: verify existing deployments work without kedaAutoscaling enabled
- [X] T049 Test mutual exclusion: verify deployment fails when both autoscaling and kedaAutoscaling are enabled
- [ ] T050 Create example values files for common scenarios in specs/001-adding-keda-i/examples/ (optional)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P2): Can start after Foundational - Builds on US1 template but independently testable
  - User Story 3 (P3): Can start after Foundational - Validates configuration from US1, no new templates
- **Documentation (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Creates the core ScaledObject template with metric triggers
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Adds cron triggers to existing ScaledObject template (extends T011-T023)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Validates and documents anti-flapping configuration (no new templates)

### Within Each User Story

- **US1**: Template creation (T011) must complete before adding sections (T012-T021)
- **US2**: Cron trigger implementation (T024-T027) extends the template from US1
- **US3**: Verification tasks (T031-T037) validate existing configuration

### Parallel Opportunities

- **Phase 1**: T003 can run parallel with T001-T002
- **Phase 2**: T006, T007, T008 (validation logic) can run in parallel; T009-T010 (template updates) can run in parallel after T004-T005
- **Phase 6**: All documentation tasks (T039-T045) can run in parallel; validation tasks (T046-T049) must run sequentially

---

## Parallel Example: Foundational Phase

```bash
# After T004-T005 complete, launch validation logic together:
Task: "Create validation logic for mutual exclusion in templates/_helpers.tpl"
Task: "Create validation logic for minReplicas <= maxReplicas in templates/_helpers.tpl"
Task: "Create validation logic for required Prometheus serverAddress in templates/_helpers.tpl"

# Then launch template updates together:
Task: "Update templates/deployment-kong.yml replicas condition"
Task: "Update templates/horizontal-pod-autoscaler.yaml condition"
```

## Parallel Example: Documentation Phase

```bash
# Launch all documentation tasks together:
Task: "Add KEDA autoscaling section to README.md"
Task: "Add detailed configuration examples to README.md"
Task: "Document migration from HPA to KEDA in README.md"
Task: "Add KEDA feature entry to CHANGELOG.md"
Task: "Update quickstart.md with troubleshooting section"
Task: "Add validation commands section to quickstart.md"
Task: "Document ClusterTriggerAuthentication setup in quickstart.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Metric-Based Autoscaling)
4. **STOP and VALIDATE**: Test metric-based scaling independently
   - Deploy with CPU trigger only
   - Deploy with memory trigger only
   - Deploy with both triggers
   - Verify helm lint and helm template pass
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! - Metric-based autoscaling works)
3. Add User Story 2 → Test independently → Deploy/Demo (Schedule-based scaling added)
4. Add User Story 3 → Test independently → Deploy/Demo (Anti-flapping validated and documented)
5. Complete Documentation → Final validation → Release

### Sequential Implementation (Recommended for Helm Charts)

Since this is a Helm chart with a single template file being extended:

1. Complete Setup (Phase 1)
2. Complete Foundational (Phase 2) - Critical foundation
3. Implement User Story 1 (Phase 3) - Core template with metric triggers
4. Extend with User Story 2 (Phase 4) - Add cron triggers to same template
5. Validate User Story 3 (Phase 5) - Verify anti-flapping configuration
6. Complete Documentation (Phase 6) - Final polish

Each story builds on the previous but remains independently testable by enabling/disabling specific triggers.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable by enabling only its triggers
- Helm chart validation: Use `helm lint` after each phase
- Template validation: Use `helm template` with different values configurations
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Test configurations:
  - US1 only: `kedaAutoscaling.enabled=true`, `triggers.cpu.enabled=true`, `triggers.memory.enabled=true`
  - US2 only: `kedaAutoscaling.enabled=true`, `triggers.cron.enabled=true`
  - US3: Test with oscillating thresholds and verify cooldown/stabilization behavior
- Avoid: vague tasks, breaking backward compatibility, enabling KEDA by default

---

## Validation Checklist

After completing all tasks, verify:

- [ ] `helm lint` passes without errors
- [ ] `helm template` renders valid YAML with kedaAutoscaling.enabled=false (backward compatibility)
- [ ] `helm template` renders valid YAML with kedaAutoscaling.enabled=true and all triggers enabled
- [ ] `helm template` renders valid YAML with kedaAutoscaling.enabled=true and only CPU/memory triggers
- [ ] `helm template` renders valid YAML with kedaAutoscaling.enabled=true and only cron triggers
- [ ] `helm template` fails with clear error when both autoscaling.enabled=true and kedaAutoscaling.enabled=true
- [ ] `helm template` fails with clear error when prometheus trigger enabled but serverAddress empty
- [ ] `helm template` fails with clear error when minReplicas > maxReplicas
- [ ] README.md includes KEDA section with prerequisites and examples
- [ ] CHANGELOG.md documents the new feature
- [ ] quickstart.md includes troubleshooting and validation commands
- [ ] All constitution principles from plan.md are satisfied
