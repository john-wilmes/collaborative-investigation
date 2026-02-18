# Investigation Toolkit

Available data sources and what they can answer. Agent reads this to make specific, actionable data requests to the human investigator.

## Datadog

### APM (Application Performance Monitoring)
- Trace search by service, endpoint, status code, duration
- Error tracking with stack traces
- Service dependency maps
- **Ask for:** "Datadog APM traces for `<service>` `<endpoint>` between `<start>` and `<end>`, filtered by `<tag>`"

### Logs
- Structured log search across all services
- Correlation by trace ID
- **Ask for:** "Datadog logs matching `<query>` in `<service>` between `<start>` and `<end>`"

### Dashboards
- Pre-built dashboards for key services
- **Ask for:** "Screenshot of `<dashboard-name>` for `<timeframe>`"

## NoSQLBooster (MongoDB)

- Direct database queries
- Document inspection
- Aggregation pipelines
- **Ask for:** "MongoDB query: `db.<collection>.find(<query>)` on `<database>`"
- **Ask for:** "Count of documents matching `<query>` in `<collection>`"

## Admin Application

- Feature flag status per customer
- Deployment history
- Integration configuration
- Customer environment details
- **Ask for:** "Feature flags for `<customer>` in `<environment>`"
- **Ask for:** "Recent deployments to `<environment>` in last `<N>` days"
- **Ask for:** "Integration config for `<customer>` `<integration-name>`"

## GitHub

- CI/CD pipeline status and logs
- Pull request history and diffs
- Code search across repositories
- **Ask for:** "Recent PRs merged to `<repo>` `<branch>` touching `<path>`"
- **Ask for:** "CI logs for `<workflow>` run `<id>`"
