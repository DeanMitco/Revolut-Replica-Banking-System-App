# Lokal entwickeln

## Visual Studio

Die Hauptsolution ist `RevolutReplica.sln`. Der Projektmappen-Explorer gruppiert
die Projekte unter `src/Clients`, `src/Gateway` und `src/Services`. Dokumentation,
Infrastruktur, Filter und Tests haben eigene Solution-Ordner.

Solution-Ordner dienen nur der Darstellung. Die tatsächlichen Projektpfade bleiben
unter `src/`; Projekte immer an ihrem fachlich passenden Ort anlegen und danach
der Hauptsolution hinzufügen. Die Namen der Solution-Ordner entsprechen den
Repository-Bereichen.

### UI starten

1. Öffne `RevolutReplica.sln` über **Datei → Öffnen → Projekt/Projektmappe**.
2. Wechsle im Projektmappen-Explorer bei Bedarf zur **Projektmappenansicht**.
3. Rechtsklick auf `RevolutReplica.Client` → **Als Startprojekt festlegen**.
4. Wähle **Windows Machine** oder ein eingerichtetes Mobilgerät/Emulatorziel.
5. Starte mit **F5**.

Der MAUI-Client heißt jetzt `RevolutReplica.Client`. Falls Visual Studio noch die
entfernte Client-Solution oder den alten Projektpfad anzeigt, schließe die alte
Solution und öffne die Hauptsolution erneut. Benutzerbezogene `.vs`-/`.suo`-Dateien
gehören nicht in Git.

### Mehrere Projekte starten

`RevolutReplica.slnLaunch` enthält gemeinsame Profile:

| Profil | Gestartete Projekte |
| --- | --- |
| `Client` | MAUI-Client |
| `Backend` | Gateway und alle fünf Services |
| `Full Stack` | Backend und MAUI-Client |

Wähle das Profil in der Startauswahl von Visual Studio. Falls es nicht angezeigt
wird, öffne über den Rechtsklick auf die Solution **Startprojekte konfigurieren**.
Je nach Visual-Studio-Version muss **Multi-Project Launch Profiles** in den
Optionen unter den Vorschaufeatures aktiviert sein. Für den MAUI-Client das
passende Plattformziel auswählen. Die Profile starten keine Docker-Container und
warten nicht auf die Bereitschaft der anderen Prozesse.

Microsoft beschreibt [gemeinsame Startprofile](https://learn.microsoft.com/en-us/visualstudio/ide/how-to-set-multiple-startup-projects?view=visualstudio)
und [Solution-Filter](https://learn.microsoft.com/en-us/visualstudio/msbuild/solution-filters?view=visualstudio).

## Voraussetzungen und Build

Das Repository legt über `global.json` SDK `10.0.403` fest und akzeptiert neuere
Patches derselben 10.0.4xx-SDK-Reihe. Der Backend-Build benötigt keine MAUI-Workloads.
Für MAUI sind die zum Ziel passenden Workloads, Plattform-SDKs und gegebenenfalls
ein Simulator nötig. Apple-Ziele benötigen eine passende Mac-/Xcode-Buildumgebung.

Alle folgenden Befehle im Repository-Hauptverzeichnis ausführen:

```powershell
# Vollständige Solution, Client auf Windows begrenzt:
dotnet build RevolutReplica.sln -p:ClientTargetFrameworks=net10.0-windows10.0.19041.0

# Backend, auch ohne MAUI-Installation:
dotnet build solutions/Backend.slnf

# Nur der Windows-Client:
dotnet build solutions/Client.slnf -p:ClientTargetFrameworks=net10.0-windows10.0.19041.0

# Optional: Android-Client mit eingerichteter Android-Buildumgebung:
dotnet build solutions/Client.slnf -p:ClientTargetFrameworks=net10.0-android
```

`ClientTargetFrameworks` wird nur im Client-Projekt ausgewertet. Ohne diese
Eigenschaft verwendet das Projekt seine ursprünglichen Plattformziele. Der
Build aller Ziele setzt deshalb sämtliche benötigten Plattform-Tools voraus.

`src/Directory.Build.props` setzt die Backend-Compilerregeln, einschließlich
Warnungen als Fehler. Der MAUI-Bereich besitzt bewusst eine eigene
`src/Clients/Directory.Build.props`; dadurch bleiben seine Buildregeln unabhängig.
`.editorconfig` vereinheitlicht die Formatierung beim Bearbeiten in Visual Studio.

## Lokale Infrastruktur

Docker mit Compose v2 und Linux-Containern wird für SQL Server und RabbitMQ benötigt.
Die bisherigen Hosts prüfen aktuell nur ihre eigene Erreichbarkeit und verbinden
sich noch nicht mit diesen Diensten.

Bei einem frischen Clone `.env.example` nach `.env` kopieren und die lokalen
Zugangsdaten setzen. Eine bereits vorhandene `.env` nicht überschreiben.
Die Datei ist von Git ausgeschlossen.

```powershell
# Nur falls .env noch nicht existiert:
Copy-Item .env.example .env
# Anschließend .env bearbeiten.

docker compose config --quiet
docker compose up -d sqlserver rabbitmq
docker compose run --rm sqlserver-init
docker compose ps
```

Der Initialisierungsjob wartet auf SQL Server und legt die Service-Datenbanken
wiederholbar an. Vorhandene Datenbanken bleiben erhalten. Bei Erfolg beendet sich
der Job mit Exitcode 0. Ein normales `docker compose up -d` startet den Job ebenfalls;
Status und Ausgabe sind über `docker compose ps -a` und
`docker compose logs sqlserver-init` sichtbar.

SQL Server läuft unter `localhost,1433`, RabbitMQ-AMQP unter `localhost:5672` und
die RabbitMQ-Verwaltung unter [localhost:15672](http://localhost:15672). Der VHost
heißt `revolutreplica`. Zugangsdaten stehen in der lokalen `.env`.

Compose lädt `.env`; ASP.NET Core tut dies nicht automatisch. Bei der späteren
Integration .NET User Secrets oder Umgebungsvariablen pro Service verwenden.
Die `UserSecretsId` der API-Projekte bleibt erhalten. Das SQL-Konto `sa` dient
nur dem lokalen Bootstrap und der Administration. Für die Implementierung
separate Anwendungskonten und Migration-Zugänge je Datenbank anlegen.

`docker compose down` stoppt die Infrastruktur und erhält die benannten Volumes.
Eine Änderung in `.env` ändert keine bereits in den Volumes gespeicherten
Zugangsdaten. `2022-latest` ist ein aktualisierbarer Entwicklungs-Tag; für eine
spätere Deployment-Pipeline die Images über Digests festlegen.

## Backend-Ports und Health Checks

| Host | HTTP-Port | Eigene SQL-Datenbank |
| --- | --- | --- |
| Gateway | 5000 | Keine |
| Identity & KYC | 5001 | `RevolutReplica.Identity` |
| Accounts & Ledger | 5002 | `RevolutReplica.Accounts` |
| FX | 5003 | `RevolutReplica.Fx` |
| Fraud & Audit | 5004 | `RevolutReplica.FraudAudit` |
| Notifications | 5005 | `RevolutReplica.Notifications` |

Beispiel für einen einzelnen Host:

```powershell
dotnet run --project src/Gateway/RevolutReplica.Gateway --launch-profile http
# In einem zweiten Terminal:
Invoke-RestMethod http://localhost:5000/health/public
```

Alle Hosts haben den Endpunkt `/health/public` mit der Antwort `Healthy`.
Er prüft aktuell weder SQL Server noch RabbitMQ. Die HTTP-Profile binden für die
lokale Entwicklung an localhost. Authentifizierung und TLS-Konfiguration gehören
zur weiteren Implementierung.

## Neues Projekt hinzufügen

Neue API-Projekte in `src/Services/<Fachbereich>/`, Clients unter `src/Clients/`
und Testprojekte unter `tests/` ablegen. Beispiel für ein späteres Testprojekt:

```powershell
dotnet sln RevolutReplica.sln add tests/Services/Accounts/RevolutReplica.Accounts.UnitTests/RevolutReplica.Accounts.UnitTests.csproj --solution-folder tests/Services/Accounts
```

Der Beispielbefehl setzt ein bereits angelegtes Projekt voraus. Bei neuen
ausführbaren Backend- oder Client-Projekten zusätzlich den betreffenden
`.slnf`-Filter und gegebenenfalls die Startprofile erweitern. Die Mitgliedschaft
in der Anwendung wird ausschließlich über die Hauptsolution gepflegt.
