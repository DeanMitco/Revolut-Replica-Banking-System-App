RevolutReplica - Banking System (Hybrid)

This project is based on the banking app Revolut, where such as implementing EDA (Event-Driven Architecture) and minimal frauch detection mechanisms.
The Bank Management System is built using C#, SQL Server, and .NET MAUI native.

The reason I chose .NET MAUI is because of this article:
https://www.c-sharpcorner.com/article/difference-between-net-maui-and-blazor-hybrid-and-when-should-i-use-each?srsltid=AYCX9vJasjCcaTjannDj_blX9Jf1UnQzwBgbquX4nMoVo7QSC23gjnWw

It's very precise about the use cases of the Tech Stack, what I mean by that, is that MAUI more on the performance-critical apps side is.

The colors are from "https://coolors.co/" 1. #5E6973 2. #000000 3. #F1F2F6 and the pop 4. #02C39A 5. #BF1363

Main focus in this project will be the backend such as client transactions, security and logging.

Some features I have in mind:
Deposit & Withdraw
Success and confirmation messages
Transfer funds between two accounts (ACID)
Currency Exchange, also with random value so every 1h it's changing value.
KYC - (Know your customer)
Authentification with JWT (JSON Web Tokens), Passwort over ASP.NET Core Identity
Audit-Logs
IBAN - generator


Tech Stack used in the project:

    Language: C#
    Frontend: .NET MAUI (MVVM)
    Database: SQL Server
    API Gateway: YARP
    Architecture: Microservices
    Message Broker: RabbitMQ
    Saga Pattern: MassTransit
    Orchestration local: .NET Aspire
    Orchestration production-grade: Kubernetes

By avoiding monolithic architecture we ensure, that our application is scalable, has a rapid deployment & iteration anf fault isolation.
Some drawbacks are the complexity, simplicity to set up and monitoring.

https://www.geeksforgeeks.org/software-engineering/monolithic-vs-microservices-architecture/

![Monolith vs Microservices Architecture](different-architecture-designs.png) - image from nasscom community


Architecture details:

Reason behind C#?

Very simple, I have and I am programming C# it is the best language to choose right now, so I don't have to focus on so many new implementations at once. It was a tactical decision.

Why .NET MAUI and not .NET Blazor or React?
Same as for this, I already have hands on experience with .NET MAUI, also with Blazor but not as much and that is the reason will stick with .NET MAUI.

Database  as SQL Server with SSMS (SQL Server Management Studio)

This has the best compatiblity with C# and is also a very fast and scalable relational Database.
A NoSQL Database just isn't enough for the ACID-charactestics, altough NoSQL points to performance and scalability.

How come YARP (Yet Another Reverse Proxy) as the API Gatway?

It is Open-Source, it has been programmed for the .NET Ecosystem and it is as a NuGet-Package to install. Easy and straightforward.
The second option was Ocelot, but it lacks the compatibility in my point of view.

Compatibility as in:
1. Security (Zero Trust)
2. Auditing & Compliance
3. Small latency, which is crucial for a banking system

I do have to say, the Dashboard will be a hustle, where Ocelot has a plus point. It would be easier in Ocelot to implement these nice to have features.
Nevertheless, exchanging beauty for performance and security should be on number 1 place.

Example of an API-Gateway

![Image of API-Gateways with ocelot](eShopOnContainer-with-Ocelot.png) - image from microsoft learn

CI/CD Implementation and Homelab-DevOps dependency and relationship

• The Architecture: A microservices application deployed to Azure.
Core Focus: GitOps, Kubernetes, and automated security.
• Implementation Steps:
1. CI Stage: Set up GitHub Actions to run unit tests, build Docker images, and immediately scan them for vulnerabilities using Trivy.
2. Secret Management: Integrate HashiCorp or Azure Key Vault so secrets are injected dynamically at runtime rather than stored in Git.
3. CD (GitOps) Stage: Set up ArgoCD inside the Kubernetes cluster. Configure it to monitor a separate gitops-manifests repository. When GitHub Actions updates the image tag in the manifests repo, ArgoCD automatically syncs and deploys it.
4. Policy & Monitoring: Implement Kyverno to block non-compliant images and use Prometheus/Grafana to track deployment metrics (deployment frequency, lead time for changes).

Architecture Diagram (Design):
C4 Model

Level 1 - System Context Diagram

```mermaid
C4Context
    title System Context Diagram - RevolutReplica

    Person(customer, "Banking Customer", "Manages wallets, exchanges currencies, and transfers money via mobile")
    
    System(bankingSystem, "RevolutReplica System", "Hybrid cloud-native banking platform with ACID ledger, FX rates, and EDA fraud checks")
    
    System_Ext(fxFeed, "FX Rate Simulator", "Generates simulated hourly currency exchange rates")

    Rel(customer, bankingSystem, "Views balances, transfers funds, checks KYC", "HTTPS / SignalR")
    Rel(fxFeed, bankingSystem, "Feeds hourly exchange rates", "Internal Timer / Event")
```

Level 2 - Container Diagram

```mermaid
C4Container
    title Container Diagram - RevolutReplica Microservices

    Person(customer, "Banking Customer", "Mobile User")

    Container(mauiApp, ".NET MAUI Mobile App", "C#, XAML, MVVM", "Native mobile UI for transfers, FX, and real-time alerts")

    System_Boundary(k8s, "Kubernetes Cluster (AKS / Homelab)") {
        Container(yarp, "API Gateway", "C#, YARP", "Single entry point, Zero-Trust JWT validation, rate limiting, routing")

        Container(identitySvc, "Identity & KYC Service", "ASP.NET Core", "Handles registration, ASP.NET Identity, JWT tokens, and KYC status")
        Container(ledgerSvc, "Account & Ledger Service", "ASP.NET Core, MassTransit", "IBAN generator, multi-currency wallets, double-entry ACID ledger")
        Container(fxSvc, "FX Service", "ASP.NET Core Worker", "Updates exchange rates every 1h and handles currency conversions")
        Container(fraudAuditSvc, "Fraud & Audit Service", "ASP.NET Core, MassTransit", "Consumes events to check fraud rules and write immutable audit logs")
        Container(notifSvc, "Notification Service", "ASP.NET Core, SignalR", "Pushes real-time transfer confirmations and fraud alerts")

        ContainerQueue(rabbitmq, "Message Broker", "RabbitMQ", "Event bus for EDA (TransferCompleted, FraudAlerted, RateUpdated)")

        ContainerDb(identityDb, "Identity DB", "SQL Server", "Users, roles, password hashes, KYC records")
        ContainerDb(ledgerDb, "Ledger DB", "SQL Server", "Accounts, IBANs, double-entry ledger rows, Outbox messages")
        ContainerDb(auditDb, "Audit & Fraud DB", "SQL Server", "Append-only audit trail and flagged transactions")
    }

    Rel(customer, mauiApp, "Uses")
    Rel(mauiApp, yarp, "API Calls (JWT)", "HTTPS / JSON")
    Rel(notifSvc, mauiApp, "Real-time Push Alerts", "WebSockets / SignalR")

    Rel(yarp, identitySvc, "Routes /auth & /kyc", "HTTP")
    Rel(yarp, ledgerSvc, "Routes /accounts & /transfers", "HTTP")
    Rel(yarp, fxSvc, "Routes /fx", "HTTP")

    Rel(identitySvc, identityDb, "Reads/Writes", "EF Core")
    Rel(ledgerSvc, ledgerDb, "ACID Transactions + Outbox", "EF Core")
    Rel(fraudAuditSvc, auditDb, "Appends Logs", "EF Core")

    Rel(ledgerSvc, rabbitmq, "Publishes TransferCompleted", "AMQP")
    Rel(fxSvc, rabbitmq, "Publishes ExchangeRateUpdated", "AMQP")
    Rel(rabbitmq, fraudAuditSvc, "Delivers Events", "AMQP")
    Rel(rabbitmq, notifSvc, "Delivers Events", "AMQP")
    Rel(fraudAuditSvc, rabbitmq, "Publishes FraudFlagged", "AMQP")
```

Level 3: Component Diagram

```mermaid
C4Component
    title Component Diagram - Account & Ledger Service

    Container(yarp, "YARP API Gateway", "Routes authenticated requests")
    ContainerDb(ledgerDb, "Ledger DB", "SQL Server")
    ContainerQueue(rabbitmq, "RabbitMQ", "Event Broker")

    Container_Boundary(ledgerService, "Account & Ledger Service (ASP.NET Core)") {
        Component(transferCtrl, "Transfers Controller", "Minimal API / Controller", "Validates Idempotency-Key header & JWT user claims")
        Component(ibanGen, "IBAN Generator", "C# Domain Service", "Generates valid unique IBANs for new multi-currency wallets")
        Component(ledgerEngine, "Double-Entry Ledger Engine", "C# Domain Logic", "Creates balanced Debit + Credit entries and verifies sufficient funds")
        Component(outboxRepo, "EF Core + MassTransit Outbox", "Persistence Layer", "Commits ledger entries and integration events in a single SQL ACID transaction")
    }

    Rel(yarp, transferCtrl, "POST /api/transfers", "HTTP")
    Rel(transferCtrl, ibanGen, "Requests new IBAN on account creation")
    Rel(transferCtrl, ledgerEngine, "Executes transfer command")
    Rel(ledgerEngine, outboxRepo, "Persists Debit, Credit & Outbox Event")
    Rel(outboxRepo, ledgerDb, "BEGIN TRAN ... COMMIT", "SQL / EF Core")
    Rel(outboxRepo, rabbitmq, "Background relay publishes event", "AMQP")
```


Resources:
Architecture Design:
https://c4model.com/
https://www.visual-paradigm.com/guide/c4-model-case-study-modernizing-internet-banking/
https://c4model.com/abstractions/microservices
https://medium.com/@gauravtiwari9098/c4-modeling-7dd8ae379f73

Microservices Architecture Design:
https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/microservice-application-design
https://learn.microsoft.com/de-de/dotnet/architecture/cloud-native/introduce-eshoponcontainers-reference-app
https://github.com/dotnet-architecture/eshoponcontainers/wiki/Architecture
https://aspire.dev/architecture/overview/



