# Feature Specification: KEDA-Based Autoscaling for Gateway

**Feature Branch**: `001-adding-keda-i`  
**Created**: 2025-10-13  
**Status**: Draft  
**Input**: User description: "Adding Keda: I want to have automatically scaling gateway instances in a more cost-effective manner based on the actual and usual load on the cluster. I want to be able to automatically react to increases and decreases of load in a timely manner. It shall be possible to scale based on metrics and resource consumption as well as time-boxed scaling. Sensible adjustments to the scaling config shall be made to prevent unwanted behavior such as flapping."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Metric-Based Autoscaling (Priority: P1)

As a platform operator, I need the gateway to automatically scale up when traffic increases and scale down when traffic decreases, so that I can maintain performance during peak times while reducing costs during low-traffic periods.

**Why this priority**: This is the core value proposition - automatic scaling based on actual load is the primary cost-saving and performance-maintaining capability. Without this, the feature provides no value.

**Independent Test**: Deploy gateway with metric-based autoscaling enabled for both CPU and memory thresholds. Generate increasing traffic load and observe pod count increasing when either CPU or memory thresholds are exceeded. Reduce traffic and observe pod count decreasing after cooldown period. Verify response times remain acceptable throughout.

**Acceptance Scenarios**:

1. **Given** gateway is running with 2 replicas and low traffic, **When** traffic increases beyond the configured threshold, **Then** additional gateway pods are created within the configured scale-up window
2. **Given** gateway is running with 5 replicas and traffic decreases, **When** traffic remains below threshold for the cooldown period, **Then** gateway pods are removed gradually to the minimum replica count
3. **Given** gateway is under sustained high load, **When** scaling reaches the maximum replica limit, **Then** no further pods are created and existing pods handle the load
4. **Given** autoscaling is enabled with CPU threshold at 70%, **When** average CPU usage across pods exceeds 70%, **Then** scaling is triggered within the configured evaluation window
5. **Given** autoscaling is enabled with memory threshold at 80%, **When** average memory usage across pods exceeds 80%, **Then** scaling is triggered within the configured evaluation window
6. **Given** both CPU and memory thresholds are configured, **When** either metric exceeds its threshold, **Then** scaling is triggered based on the metric that exceeds its threshold first

---

### User Story 2 - Schedule-Based Scaling (Priority: P2)

As a platform operator, I need the gateway to scale based on time schedules to proactively handle known traffic patterns, so that capacity is available before predictable load increases occur.

**Why this priority**: Many organizations have predictable traffic patterns (business hours, batch jobs, etc.). Proactive scaling prevents performance degradation during known peak times and further optimizes costs during known low-traffic periods.

**Independent Test**: Configure schedule-based scaling with specific time windows. Verify gateway scales up at the scheduled time before traffic arrives. Verify gateway scales down at the scheduled off-peak time. Confirm this works independently of metric-based scaling.

**Acceptance Scenarios**:

1. **Given** schedule-based scaling is configured for business hours (8 AM - 6 PM), **When** 8 AM arrives, **Then** gateway scales to the configured business-hours minimum replica count
2. **Given** gateway is scaled for business hours, **When** 6 PM arrives, **Then** gateway scales down to the off-hours minimum replica count
3. **Given** both schedule and metric-based scaling are enabled, **When** scheduled scale-up occurs, **Then** metric-based scaling can still scale beyond the scheduled minimum if load requires it
4. **Given** multiple schedules are configured for different days, **When** the schedule transitions, **Then** the appropriate replica count is applied for the current schedule

---

### User Story 3 - Anti-Flapping Protection (Priority: P3)

As a platform operator, I need the autoscaling system to prevent rapid scale-up and scale-down cycles, so that the gateway remains stable and doesn't waste resources on constant pod churn.

**Why this priority**: While important for stability, this is a refinement of the core scaling behavior. The system can function without sophisticated anti-flapping, though it may be less efficient.

**Independent Test**: Create oscillating traffic patterns that cross the scaling threshold repeatedly. Verify that scaling decisions are dampened by cooldown periods and stabilization windows. Confirm pods aren't created and destroyed in rapid succession.

**Acceptance Scenarios**:

1. **Given** gateway just scaled up, **When** traffic briefly drops below threshold, **Then** no scale-down occurs until the cooldown period expires
2. **Given** gateway just scaled down, **When** traffic briefly spikes above threshold, **Then** scale-up is delayed by the stabilization window to confirm sustained load
3. **Given** traffic oscillates around the threshold, **When** evaluation windows are configured appropriately, **Then** scaling decisions are based on sustained trends rather than momentary spikes
4. **Given** multiple scaling triggers are active, **When** one trigger suggests scale-up and another suggests scale-down, **Then** the system prioritizes availability (scale-up) over cost savings (scale-down)

---

### Edge Cases

- What happens when the autoscaler is enabled but the scaling metric source is unavailable or unreachable?
- How does the system handle scaling during a rolling update of the gateway deployment?
- What occurs if the minimum replica count is set higher than the maximum replica count?
- How does the system behave when node resources are exhausted and new pods cannot be scheduled?
- What happens if the autoscaler is disabled while pods are scaled beyond the static replica count?
- How are scaling decisions affected when multiple metrics simultaneously trigger different scaling directions?
- What occurs during the transition from schedule-based minimum to metric-based scaling?
- How does the system behave when CPU is high but memory is low, or vice versa?
- What happens if memory thresholds are reached but CPU remains low for an extended period?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Chart MUST support enabling/disabling autoscaling via a configuration flag that is independent of the existing HPA autoscaling
- **FR-002**: Chart MUST allow configuration of minimum and maximum replica counts for autoscaling boundaries
- **FR-003**: Chart MUST support scaling based on CPU utilization percentage as a metric
- **FR-004**: Chart MUST support scaling based on memory utilization percentage as a metric
- **FR-005**: Chart MUST support scaling based on custom metrics (e.g., request rate, active connections, queue depth)
- **FR-006**: Chart MUST support schedule-based scaling with configurable time windows and replica counts
- **FR-007**: Chart MUST allow configuration of scale-up and scale-down cooldown periods to prevent flapping
- **FR-008**: Chart MUST allow configuration of evaluation windows for metric-based scaling decisions
- **FR-009**: Chart MUST support configuration of metric thresholds that trigger scaling actions
- **FR-009a**: Chart MUST allow independent threshold configuration for CPU and memory metrics (e.g., CPU at 70%, memory at 80%)
- **FR-010**: Chart MUST disable or remove standard HPA when KEDA-based autoscaling is enabled to prevent conflicts
- **FR-011**: Chart MUST provide sensible default values for all autoscaling parameters that prevent aggressive scaling behavior
- **FR-012**: Chart MUST validate that minimum replica count is less than or equal to maximum replica count
- **FR-013**: Chart MUST allow operators to configure multiple scaling triggers that work together
- **FR-014**: Chart MUST support graceful fallback behavior when autoscaling is disabled (revert to static replica count)
- **FR-015**: Chart MUST document all autoscaling configuration parameters in values.yaml with inline comments
- **FR-016**: Chart MUST maintain backward compatibility with existing deployments that don't use autoscaling

### Assumptions

- KEDA is already installed in the target Kubernetes cluster or will be installed separately (not bundled with this chart)
- Prometheus or equivalent metrics source is available for custom metric-based scaling
- Operators understand their traffic patterns well enough to configure appropriate thresholds
- The existing HPA autoscaling feature will be deprecated in favor of KEDA but maintained for backward compatibility
- Schedule-based scaling uses UTC timezone unless cluster-specific timezone configuration is available

### Key Entities

- **Scaling Trigger**: Represents a condition that causes scaling (metric threshold, schedule, resource utilization). Contains trigger type, threshold values, evaluation window, and cooldown settings.
- **Scaling Policy**: Defines the overall autoscaling behavior including min/max replicas, enabled triggers, and anti-flapping parameters. Associated with the gateway deployment.
- **Metric Source**: External system providing scaling metrics (Prometheus, Kubernetes metrics server, custom endpoints). Referenced by metric-based triggers.
- **Schedule Window**: Time-based period with associated replica count requirements. Contains start time, end time, days of week, and target replica count.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Gateway automatically scales from minimum to maximum replicas within 2 minutes when sustained load exceeds configured thresholds
- **SC-002**: Gateway automatically scales down from maximum to minimum replicas within the configured cooldown period (default 5 minutes) when load drops below thresholds
- **SC-003**: Infrastructure costs are reduced by at least 30% during off-peak hours compared to static replica counts sized for peak load
- **SC-004**: Response time p95 latency remains below 500ms during scaling events (both up and down)
- **SC-005**: No more than 1 scaling event occurs per 5-minute window under oscillating load conditions (anti-flapping effectiveness)
- **SC-006**: Schedule-based scaling transitions occur within 30 seconds of the configured schedule time
- **SC-007**: Operators can successfully deploy the chart with autoscaling enabled using only documented configuration parameters
- **SC-008**: Existing deployments can upgrade to the new chart version without autoscaling being automatically enabled (backward compatibility)
- **SC-009**: Gateway scales based on memory utilization when memory threshold is exceeded, even if CPU utilization remains below its threshold
