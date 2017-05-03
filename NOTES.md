# Features

- self-updating services (with option to disable)
    - for command line, it manages a local cache of binaries so multiple repos
      can pin it at different versions and it silently uses pinned version
    - based on channels which are simply branches upstream
    - pin based on commit-ish or repo+commit-ish
- local runtime of pipelines with minimal remote deployment overhead and
  maintenance
    - dark upgrades? do we upgrade, see if everything passes and rollback if
      something fails on a prior passing job?  warn of failed upgrade needing
      attention? could have simple strategy (run latest passing and see if ok)
      or complex strategy (run X recent or random jobs and require passing)
    - local runtime pinning could use similar dark upgrade approach to advise
      user of new successful versions
- hooks/integrations written in go and run in process
- test planning and discovery
    - planning includes leveling runtime over parallel workers to optimize end
      to end runtime
- run operations based on file change paths
    - ie: if you added files to a `*/migrations/*` path, run db migrations
    - requires ability for system to know how long since the last
      run/deploy/... (could give raw access to that information in the form
      of a git commit it was last run at)

# attributes of services

## Administrator

This is the individual with rights to change and configure the service.  This
includes plugins.

## Lifecycle

The lifetime of a service.  How long it should live from start to finish. What
or who starts it?  What or who kills it?  When does it stop?

## Runtime

The behavior of the service.  Some services can run start to finish and quit,
others are to be long lived processes or daemons.

# Internal APIs

- Provider (AWS, Kubernetes, ...)
- Object Storage (proxying to S3, Artifactory, ...)
- Structured Storage (database postgres, ...)
- Log Storage
    - sidenote: unclear if this should be completely different backend storage
      or if it should use an object storage or structured storage backend...
      perhaps thats deployment implementation detail

TODO more definition of APIs

## Provider

Is responsible for reconciliation of services at various levels.  For instance,
the "api/central/..." server is responsible for reconcilication of running
repo managers; the repo manager is responsible for reconcilication of running
branch managers; the repo manager is responsible for reconciliation of running
jobs/agents.

Example providers:

- AWS
- Local process
- Docker local/remote
- Kubernetes

Hooks for smart management of disk:

- Clone once
- Build once
- Snap and mount
- smart object storage (ability to exploit local cache if possible)

# Job API

What are the actions that a job can use to communicate with the different
services?  How does it discover those?

    % env | grep GZL_
    GZL_API=http://localhost

TODO more aspects of this API
TODO more definition of this API

# main services

All services may use the Storage API to persist details of their operation, but
_must not_ store local state (services are stateless).

- "api/central/..." server
- repo manager + branch managers (as necessary)
- node manager
- agents (actually run pipeline)

## "api/central/..." server

This isn't required but facilitates centralized deployments.

Job Description:

- provision storage for manager and its agents
- centralized authentication and authorization
- enables discovery mechanisms and/or cross pipeline synchronization/messaging
- provisions repo managers upon registration request
    - reponsible for deprovisioning when repo disappears (not time sensitive)
- control of pushdown hooks and maintenance
    - forcibly run hooks on push/commit on registered repos (unclear if
- upstream checking of updates and storage of upstream or local versions of
  gzl for clients to use for updates

Administrator: organization/team level
Lifecycle: organization/team lifetime
Runtime: blocking at cmdline or daemon

## repo manager + branch managers (as necessary)

Required only for deployments that want hooks based on repository operations.
For localhost deployments, that may mean it should be able to notice commits in
its registered repo and automatically run associated pipelines based on that
action.  For remote deployments, that would mean watching pull requests or
branches for activity and taking similar action to run associated pipelines.
Managers use agents for _all_ runtime actions requested by repository (security
concern and environment mismatch issues; manager isnt required to run in same
environment required by pipeline workloads).

Another aspect of the manager is general repo maintenance.  Cron-based services
which launch agents to do maintenance on repository or associated services
(issue cleanup, pull request cleanup, auto-tag, ...).

Job Description:

- hook management
    - when _repo event_, run operation
    - when cron event, run operation
- manage plugins for repository
- upon repo deletion, advise "api/central/..." server and/or self-deprovision
- manages
    - retention of storage (logs or other artifacts)
    - synchronization of pipelines within repo
    - synchronization between other repo managers and/or with
      "api/central/..." server
    - agent lifecycle
    - metadata management
    - communication with node managers if existing
        - sidenote: feels like we need a higher level API to balance between
          running jobs on provisioned _node managers_ vs on-demand spin up
          of pods (perhaps this is an implementation detail of a specific
          Provider and we initialize a provider that makes sense for this case;
          or does the provider always make room for this and just default to
          on-demand when no node managers exist)
- some use cases
    - auto-merging functionality
    - clean up old issues and/or pull requests on associated github repo
    - watch github organization/bitbucket project and register new repos
    - manager of a branch differs from that of the repo
        - sidenote: feels like we need some kind of master manager for a repo;
          branch managers are effectively only responsible for branch and are
          somehow limited compared to the master manager (determined by the
          _master_ branch of the repo... by default "master")

Administrator: repo committer
Lifecycle: repo lifetime
Runtime: blocking at cmdline or daemon

## node manager

Ability to run agents on remote systems.  Connects to "api/central/..." server
or directly to repo manager.

Administrator: Node admin
Lifecycle: Node lifetime
Runtime: blocking at cmdline or daemon on system

## agents (actually run pipeline)

The agent is the communication and heartbeat broker for any job run in the
pipeline.  It runs right next to the job workload.  In kubernetes speak, it
is a separate container within the same pod.  In standard process speak, it
runs the commands as child processes of itself.

Job Description:

- keep manager informed of liveness of job
- proxy communication to/from job to manager
- record job runtime resource usage

Administrator: repo committer can change runtime agent, but manager directly
interfaces with it
Lifecycle: Job lifetime (start/end adhoc via cmdline; manager
starts/stops/kills it)
Runtime: blocking at cmdline or in background on remote system

# Job

Jobs are grouped together based on the commit-ish they are run for.  There may
be multiple jobs per commit-ish.  A job id is unique across all jobs.

## Idempotent

Rerunning a commit-ish is by default not allowed because result _should_ be
the same.

## Metadata

Tracking runtime of stages. Tracking resource usage over time.

Allow commenting on jobs to give background and communicate.

## Notification

TODO pre/post notifications? how do we keep noise down?  Minimal notifications

## Stages

Steps within a stage depend on eachother.  Separate stages are idempotent and
can be run in parallel.

Stages can feed input into future stages in an A+/Promise-like fashion.  Stages
can depend on stages from other repos.  Simple make-like definition.

    stage1:
        gcc myprogram.c -o myprogram
        gzl obj-store myprogram

    stage2:
        gcc myprogram2.c -o myprogram2
        gzl obj-store myprogram2

    stage3: stage1 stage2
        gzl obj-get myprogram
        gzl obj-get myprogram2
        ./myprogram ./myprogram2

While it looks/feels like make, it won't be as flexible.  It won't be strict
about tabs, just about indentation. (re-implementing make is out of scope)
Need a mechanism for dynamic stage creation and dependency creation.

## Timeout

By default, no timeouts exist.  But a timeout can be set.  Timeout can be
overall runtime or since the last log message received.

# cmdline UX

    gzl attach <commit-ish|job-id>

    gzl bisect # find breaking offending commit

    gzl debug [job-id] # drops into shell

    gzl deploy [provider]

    gzl init

    gzl logs <job-id>

    gzl list|ls # list recent commit-ish runs + jobs per commit-ish
    # estimated time to finish for unfinished jobs

    gzl manage-branch
    gzl manage-node
    gzl manage-repo

    gzl run [provider]
    gzl run [provider] --debug # drops into shell post-execution

    gzl register ["api/central/..." server]

    gzl stop <job-id>

    gzl sync/replicate # move storage around (object, structured data, ...)

# web UX

No input on web initially.  Purely read and enhance discoverability/exploration
of data.

- React/Websockets/highlighting
- realtime log tailing/progressive enhancement for multiple/parallel logs
- centered around commit-ish
- overall progress summary
- easy high level of history
