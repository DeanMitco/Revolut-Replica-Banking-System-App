# RevolutReplica

A solo learning project for .NET microservices, event-driven banking workflows,
and eventually Kubernetes, CI/CD, and GitOps. Uses synthetic financial data.

## Current milestone: Step 1

Backend solution and infrastructure scaffolding only. Identity/KYC, JWT,
gateway routing/rate limiting, ledger operations, FX simulation, messaging,
fraud checks, and SignalR are not implemented yet. Confirm Step 1 before
starting Step 2. Build and exercise the backend locally before MAUI or Kubernetes.

This README follows the current five-service architecture. The earlier
`docs/PreparationChatGpt.md` proposal describes a different, superseded
modular-monolith plan. The existing MAUI source is under `src/Clients/RevClient/`.

```text
RevolutReplica.sln                   # Backend only: no MAUI workload required
RevolutReplica.Client.slnx           # Existing MAUI client only
global.json                         # Stable .NET 10 SDK selection
src/
  Directory.Build.props             # Backend compiler defaults only
  Clients/
    Directory.Build.props           # Keeps client compiler settings independent
    RevClient/RevClient.csproj       # Existing MAUI project
  Gateway/RevolutReplica.Gateway/
  Services/
    Identity/RevolutReplica.Identity.Api/
    Accounts/RevolutReplica.Accounts.Api/
    Fx/RevolutReplica.Fx.Api/
    FraudAudit/RevolutReplica.FraudAudit.Api/
    Notifications/RevolutReplica.Notifications.Api/
docs/
  Preparation.md
  PreparationChatGpt.md              # Historical, superseded architecture proposal
  Architecture-Design/              # Repository-local draw.io diagrams
infrastructure/sqlserver/
  create-databases.sql               # Repeatable database creation
docker-compose.yml                  # Local SQL Server, bootstrap job, RabbitMQ
.env.example                        # Credential names; no passwords
```
The gateway has the YARP package installed; routes are introduced in Step 2.
FX and Fraud/Audit use ASP.NET Core hosts so they can expose health endpoints
alongside their future background workers/consumers.

Open `RevolutReplica.sln` in Visual Studio for backend work, or
`RevolutReplica.Client.slnx` for MAUI client work. Both solution files live at
the repository root and reference their projects using relative paths. They
can be opened in separate Visual Studio windows when working on both sides.
The client project name and namespace remain `RevClient`.

## Build and run locally

Prerequisites: .NET SDK 10.0.403 (or a newer patch in the 10.0.4xx feature band),
and Docker with Compose v2 and Linux containers for the infrastructure.
The root SDK selection also applies when working on the existing MAUI solution.

From the repository root:

```powershell
dotnet restore RevolutReplica.sln
dotnet build RevolutReplica.sln --no-restore
```

The client solution is separate from this backend build. To verify the MAUI
Windows target on Windows with the matching MAUI workload installed:

```powershell
dotnet build RevolutReplica.Client.slnx --configuration Debug -p:TargetFrameworks=net10.0-windows10.0.19041.0
```

Choose the appropriate target in Visual Studio when working on another client
platform. Opening a solution does not start its projects; when the client later
calls backend APIs, start those services separately in Visual Studio or a terminal.

For a fresh clone, copy `.env.example` to `.env`, then set a strong local SQL
administrator password and RabbitMQ password. `.env` is ignored by Git.
During the initial setup, an ignored `.env` was generated locally with random
passwords; it is not part of the repository.

```powershell
# Fresh clones only; do not overwrite an existing .env:
Copy-Item .env.example .env
# Edit .env before continuing.
docker compose config --quiet
docker compose up -d sqlserver rabbitmq
docker compose run --rm sqlserver-init
docker compose ps
```

The initializer waits for SQL Server's health check and exits with code 0 on
success. It can safely be rerun: existing databases are preserved. A normal
`docker compose up -d` also starts the initializer; check its exit code with
`docker compose ps -a` and its output with `docker compose logs sqlserver-init`.

Run an API in a terminal, then probe it in another terminal:

```powershell
dotnet run --project src/Gateway/RevolutReplica.Gateway --launch-profile http
# In another terminal:
Invoke-RestMethod http://localhost:5000/health/public
```

| Host | HTTP port | Owning SQL database |
| --- | --- | --- |
| Gateway | 5000 | None |
| Identity & KYC | 5001 | RevolutReplica.Identity |
| Account & Ledger | 5002 | RevolutReplica.Accounts |
| FX | 5003 | RevolutReplica.Fx |
| Fraud & Audit | 5004 | RevolutReplica.FraudAudit |
| Notifications | 5005 | RevolutReplica.Notifications |

Use the corresponding project path with `dotnet run` for each host. Every host
exposes `/health/public`, returning `Healthy`; this proves only that the host is
running. These endpoints do not check SQL Server or RabbitMQ. Step 1 hosts do
not yet connect to either dependency. HTTP profiles bind to localhost for local
scaffolding; authentication and TLS configuration follow during Step 2.

SQL Server is available at `localhost,1433`. RabbitMQ AMQP is on `localhost:5672`,
its management UI is at <http://localhost:15672>, and its vhost is
`revolutreplica`. Credentials are in your local `.env`. ASP.NET Core does not
automatically load Compose's `.env`; configure each service with .NET user
secrets or environment variables when its integration is implemented.

The SQL `sa` credential is for local bootstrap/administration only. Introduce
separate database-scoped application logins and migration credentials when
implementing each service; never configure a service to use `sa`. No database
schemas or application permissions have been created in Step 1.

`docker compose down` stops the infrastructure while preserving named volumes.
Changing `.env` does not rotate credentials already stored in those volumes.
SQL Server's `2022-latest` development tag receives updates; pin image digests
when building the deployment pipeline.

## Rules for subsequent steps

- Accounts and Ledger form one service and one transaction boundary. Never
  update a balance independently of balanced, append-only ledger postings.
- A P2P transfer commits its debit, credit, durable idempotency result, and
  outbox entry in the same SQL transaction. Enforce `Idempotency-Key` with
  database uniqueness, request matching, and safe retries under concurrency.
- Each service owns its database and migrations. No cross-database queries,
  shared EF entities, or direct writes into another service's database.
- Use MassTransit with RabbitMQ and a transactional outbox when implementing
  events. Consumers must tolerate duplicate delivery. Sagas coordinate future
  multi-service workflows without replacing the ledger's ACID transaction.
- Validate JWTs at the gateway and in protected services. Enforce account
  ownership in the service handling the request.
- Asynchronous fraud checks detect events after posting; they cannot prevent
  an already committed transfer. Audit records are append-only.
- Preserve the MAUI palette for its later phase: `#5E6973`, `#000000`,
  `#F1F2F6`, `#02C39A`, `#BF1363`; use conventional green/red for success/alerts.

## Technical references

- [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy)
- [YARP getting started](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/getting-started?view=aspnetcore-10.0)
- [SQL Server Linux containers](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver16)
- [RabbitMQ installation](https://www.rabbitmq.com/docs/download)
- [Compose health checks and startup ordering](https://docs.docker.com/compose/how-tos/startup-order/)
