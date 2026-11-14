# RevolutReplica

Ein Lernprojekt für eine Banking-App mit **.NET MAUI**, ASP.NET Core Microservices,
SQL Server und RabbitMQ. Es verwendet synthetische Finanzdaten.

## In Visual Studio starten

**Öffne `RevolutReplica.sln` im Repository-Hauptverzeichnis.** Diese eine Solution
enthält den MAUI-Client, das Gateway und alle fünf Services.

1. Öffne die Datei über **Datei → Öffnen → Projekt/Projektmappe**.
2. Verwende im Projektmappen-Explorer die **Projektmappenansicht**.
3. Klappe `src → Clients` auf und wähle `RevolutReplica.Client` als Startprojekt.
4. Wähle für die lokale Windows-Entwicklung **Windows Machine** als Ziel und starte mit **F5**.

Für gezieltes Arbeiten gibt es zwei optionale Filter derselben Solution:

| Datei | Enthaltene Projekte |
| --- | --- |
| `RevolutReplica.sln` | Gesamte Anwendung; der normale Einstieg |
| `solutions/Client.slnf` | Nur der MAUI-Client |
| `solutions/Backend.slnf` | Gateway und Services; ohne MAUI-Workload baubar |

Die Filter sind Ansichten der Hauptsolution. Die bisherige
`RevolutReplica.Client.slnx` wurde integriert. Der bisherige Client `RevClient`
heißt jetzt `RevolutReplica.Client`.

## Repository-Struktur

```text
RevolutReplica.sln
RevolutReplica.slnLaunch             # Gemeinsame Visual-Studio-Startprofile
.editorconfig                       # Formatierung für Visual Studio
global.json                         # Festgelegte .NET-SDK-Version
docker-compose.yml                  # Lokale Datenbank und Message Broker
solutions/                          # Optionale Ansichtsfilter
src/
  Directory.Build.props             # Backend-Compilerregeln
  Clients/
    Directory.Build.props           # Unabhängige MAUI-Compilerkonfiguration
    RevolutReplica.Client/
      App.xaml                      # App-Einstieg und Ressourcen
      AppShell.xaml                 # Navigation
      MauiProgram.cs                # Dependency Injection und App-Konfiguration
      Views/                        # XAML-Seiten und UI-Code
      ViewModels/                   # Künftig Zustand und Commands (MVVM)
      Models/                       # Künftig UI-Modelle
      Services/                     # Künftig API-Zugriff und Geräteservices
      Platforms/                    # Android, iOS, MacCatalyst und Windows
      Resources/                    # Styles, Farben, Bilder und Fonts
  Gateway/
    RevolutReplica.Gateway/
  Services/
    Identity/RevolutReplica.Identity.Api/
    Accounts/RevolutReplica.Accounts.Api/
    Fx/RevolutReplica.Fx.Api/
    FraudAudit/RevolutReplica.FraudAudit.Api/
    Notifications/RevolutReplica.Notifications.Api/
tests/                              # Platz und Regeln für kommende Testprojekte
docs/
  ARCHITECTURE.md                    # Zuständigkeiten und Abhängigkeiten
  DEVELOPMENT.md                     # Build, Debugging und Infrastruktur
  Preparation.md                    # Ursprüngliche Planung
  PreparationChatGpt.md              # Historischer Alternativvorschlag
  Architecture-Design/               # Bestehende draw.io-Diagramme
infrastructure/
  sqlserver/create-databases.sql
```

Die vorbereiteten, noch leeren Ordner sind in den Projektdateien hinterlegt und
dadurch auch nach einem frischen Clone in Visual Studio sichtbar. Im Dateisystem
entstehen sie spätestens beim Hinzufügen der ersten Klasse.

## Build

Voraussetzung: .NET SDK **10.0.403** oder ein neuerer Patch derselben
10.0.4xx-SDK-Reihe. Für den Client zusätzlich die passenden MAUI-Workloads und
Plattform-SDKs installieren. Visual Studio muss das verwendete .NET SDK unterstützen.

```powershell
# Gesamte Anwendung für die lokale Windows-Entwicklung:
dotnet build RevolutReplica.sln -p:ClientTargetFrameworks=net10.0-windows10.0.19041.0

# Nur Backend, auch für Rechner ohne MAUI:
dotnet build solutions/Backend.slnf
```

`ClientTargetFrameworks` begrenzt ausschließlich den MAUI-Build. Die Backend-Projekte
bleiben bei `net10.0`; die ursprünglichen mobilen Client-Ziele bleiben verfügbar.

Die [Entwicklungsanleitung](docs/DEVELOPMENT.md) erklärt Startprofile, weitere
Plattformen, Docker und lokale Ports. Die [Architekturübersicht](docs/ARCHITECTURE.md)
zeigt, wo neue Klassen hingehören. Neue Tests folgen den Regeln in
[`tests/README.md`](tests/README.md).

## Aktueller Funktionsumfang

Die Backend-Projekte sind startbare Hosts mit `/health/public`. Das Gateway hat
das YARP-Paket bereits referenziert. Die MAUI-App enthält die bestehende Beispielseite.
Routing, Identity/KYC, JWT, Ledger-Buchungen, FX-Simulation, Messaging,
Fraud-Erkennung und SignalR sind noch umzusetzen.

Die Solution-Struktur bereitet diese Entwicklung vor; die fachlichen Regeln und
Service-Grenzen sind in [ARCHITECTURE.md](docs/ARCHITECTURE.md) festgehalten.
