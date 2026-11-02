# Preparation: RevolutReplica Banking System

As of November 1, 2026. Planned learning project using synthetic data and simulated financial transactions. The existing code is a MAUI starter project; the backend functions still need to be implemented.

## 1. Objective and Project Scope

Develop a fictional system inspired by banking apps such as Revolut. The focus is on accurate transactions, access control, structured logging, and traceable CI/CD. This project is not a real bank and has no connection to Revolut.

The client and backend will initially be hosted together in a dedicated app repository. Homelab and cloud platforms provide runtime environments and reference published backend images.

## 2. Technical Selection

| Area | Initial Decision | Rationale |
| --- | --- | --- |
| Language | C# / .NET 10 | Utilize existing knowledge and an existing MAUI project using `net10.0`. |
| Client | .NET MAUI, XAML, MVVM | Native app as a learning objective; gradually expand the existing client. |
| Backend | ASP.NET Core Web API | Clearly defined API for accounts and transactions. |
| Architecture | Modular monolith | Separate business domains; keep initial transfers within a single database transaction. |
| Persistence | EF Core with SQL Server | Existing knowledge and future Azure SQL learning goal. |
| Authentication | ASP.NET Core Identity; initially using its simple bearer tokens for the native learning client | Use framework functions for user and password hashing. |
| Gateway | None for now in addition to platform ingress | A backend API does not require its own gateway. |
| Observability | Structured logs, correlation ID, OpenTelemetry | Track requests and errors. |

The modular monolith, for example, logically separates `Accounts`, `Ledger`, `Transfers`, `Identity`, and `Audit`, but is deployed as a single backend. Subsequent spin-offs remain possible. This aligns with the [architecture model with separated responsibilities](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures).

SQL Server is a deliberate choice, not proof of “best C# compatibility.” PostgreSQL also offers an EF Core provider; switching would require reviewing providers, migrations, and queries. A fully open-source database requirement would favor PostgreSQL. See [EF Core providers](https://learn.microsoft.com/en-us/ef/core/providers/).

## 3. Clarify Previous Justifications

| Previous Assumption | More Precise Description |
| --- | --- |
| MAUI is generally faster or particularly well-suited for banking. | Chosen based on my experience and the native client. Actual performance depends on the implementation. |
| Microservices automatically make the app scalable and fault-tolerant. | Independent deployments are possible, but handling distributed failures and ensuring data consistency become more complex. |
| NoSQL cannot handle ACID transactions. | Guarantees depend on the system. The relational model is a good fit here because of relationships and atomic transactions. |
| SQL Server and SSMS are the same choice. | SQL Server is the database; SSMS is a management tool. |
| YARP guarantees greater security and lower latency than Ocelot. | Without requirements, configuration, and measurement, this claim is unsubstantiated. |
| BCrypt Vault manages secrets. | BCrypt is a password hashing algorithm. Secret management is a separate task. |
| Identity automatically issues JWTs. | The built-in Identity API bearer tokens are proprietary tokens, not JWTs. |
| The native MAUI app is deployed in Kubernetes. | The API and workers run there; native clients are built and distributed separately. |

Microsoft documents the [Identity API tokens](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-10.0) and the [MAUI platforms](https://learn.microsoft.com/en-us/ dotnet/maui/supported-platforms?view=net-maui-10.0). Apple targets require appropriate Mac/Xcode build capabilities; a Linux backend runner does not cover all client builds.

## 4. Initial Functional Scope

- Create and log in users; share data only with authorized users.
- Support demo accounts with an initial balance of EUR.
- Offer simulated deposits, withdrawals, and transfers.
- Display transaction history with transaction IDs and clear success/error messages.
- Distinguish between technical logs and business audit entries
- First, implement business logic using API tests; then integrate the MAUI client.

Real payments, real KYC documents, and distributed account databases are not part of the MVP. A demo IBAN is synthetic test data and not an actual, active account capable of making payments.

## 5. Model Money Transactions Correctly

Debits and credits are either committed together or discarded together. The ledger records both sides; corrections are made via offsetting entries. A displayed account balance must not be changed independently of its accounting basis.

For the initial EUR scope, integer cent amounts are recommended. Alternatively, precisely scaled `decimal` values are possible. Do not use `float` or `double` for these monetary calculations. The currency code and, later, the permitted decimal scale are part of the modeling.

1. The amount must be positive, the currency must match, the accounts must exist, and access to the source account must be permitted.
2. Ensure sufficient funds even under concurrency: use a suitable locking/isolation strategy or an optimistic concurrency check with a retry of the entire transaction.
3. An idempotency key with a database uniqueness rule prevents duplicate execution. The same key with modified request content is rejected.
4. Every completed transfer has balanced entries for each currency. Report success only after commit.
5. A database error must not leave a transfer half-completed. Business audit metadata records the actor, time, result, and correlation.

These rules are tested in conjunction with SQL Server. An in-memory EF provider does not guarantee SQL transaction behavior or correct concurrency.

## 6. Authentication and Secrets

For the first native learning client, use Identity with its bearer tokens and manage tokens via secure device storage. The API also checks account permissions; a login does not grant unrestricted access to the account.

JWT remains a separate learning step: select an OAuth/OIDC provider, use an authorization code with PKCE in the native client, and verify the signature, issuer, audience, and lifetime in the API. Identity can also handle user management. Microsoft describes [JWT validation and OAuth/OIDC](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-10.0).

Use local .NET user secrets or unversioned environment files. During deployment, use the environment’s secret management solution. Tokens and credentials do not belong in Git or technical logs. Leave password hashing to the configured Identity hasher.

## 7. Expansion After a Working MVP

| Step | Implementation | Acceptance |
| --- | --- | --- |
| Currency Conversion | Initially fixed demo exchange rates; later, hourly simulated rates with version and timestamp. | The transaction permanently stores the exchange rate used and the rounding. |
| KYC Demo | State transitions with synthetic data, such as `Pending` → `Approved`. | Only authorized roles can change the status; the result is auditable. |
| Fraud rules | Explainable alerts, such as when there is a conspicuously high number of transfers. | A reproducible test triggers the alert; this does not claim to be a productive fraud detection system. |
| Events | Save the transfer and outbox entry together; publish afterward. | Restarts do not lose any committed events; resending does not cause duplicate side effects. |
| First separate service | Notification worker; add RabbitMQ specifically for this purpose. | Worker failure does not prevent correct fund posting; backlog is processed later. |
| Gateway | Use YARP for multiple APIs or when true routing/aggregation is required. | A documented requirement is addressed and measured. |

The core posting remains within the same transaction scope. Distributing accounts across separate services requires a new consistency model. A broker does not establish a shared ACID transaction across its databases.

YARP is a customizable .NET reverse proxy library. This justifies its selection as a potential option but does not provide proof of security or compliance. See [YARP Getting Started](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/getting-started?view=aspnetcore-10.0).

## 8. Planned App Repo Structure and CI

```text
RevolutReplica-Banking-System-App/
├── README.md
├── Preparation.md
├── src/
│   ├── Banking.Api/           # A backend with business module folders
│   ├── Banking.Worker/        # To be added only upon reaching the event milestone
│   └── Banking.Client/        # Place the MAUI client here later
├── tests/                    # Business rules, API, and database integration
├── deploy/base/              # Versioned backend deployment base
├── compose.yaml              # Local backend dependencies
├── .gitignore
└── .gitlab-ci.yml            # Once GitLab is set up for CI
```

When migrating, retain `RevClient/` for now. A later reorganization into `src/` will be a separate step to ensure the existing solution is not moved and restructured at the same time.

Backend CI: Restore → Build → business logic tests and database integration → image build → Trivy → release. The scan must return an error status at the selected threshold. The platform selects the verified digest. Client builds receive their own jobs with appropriate operating systems and workloads.

## 9. UI Basics

The existing color palette remains: `#5E6973`, `#000000`, `#F1F2F6`, `#02C39A`, `#BF1363`. Check the contrast and readability of the combinations used. Additionally, explain success and error states with text.

## 10. Wording for the Portfolio

> I am developing a fictional banking system using C#, ASP.NET Core, and a native MAUI client. 
The initial backend implementation is planned as a modular monolith using SQL Server. 
The focus is on atomic transactions, idempotent requests, access control, and audit entries. 
Once the core has been tested, notifications and event handling will be added. 
Backend artifacts are intended to run on a separate DevOps platform in my home lab and later on Azure. 
Currently, the MAUI starter project exists.