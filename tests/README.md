# Tests

Dieser Bereich ist für kommende Testprojekte vorbereitet. Aktuell gibt es noch
keine automatisierten Fachtests; ein erfolgreicher Build ersetzt sie nicht.

Neue Tests nach dem verantwortlichen Service ordnen:

```text
tests/
  Clients/
    RevolutReplica.Client.UnitTests/
  Services/
    Accounts/
      RevolutReplica.Accounts.UnitTests/
      RevolutReplica.Accounts.IntegrationTests/
    Identity/
      RevolutReplica.Identity.UnitTests/
      RevolutReplica.Identity.IntegrationTests/
  Architecture/
    RevolutReplica.ArchitectureTests/
```

Die gezeigten Projekte werden mit der jeweiligen Funktion angelegt. Dann der
Hauptsolution unter `tests` hinzufügen; der Namespace folgt dem Projektnamen.

- Unit-Tests prüfen fachliche Regeln und Anwendungsfälle ohne Netzwerk oder Datenbank.
- Integrationstests prüfen APIs, Persistenz und Messaging mit den tatsächlichen
  Abhängigkeiten. SQL-Transaktionen und Nebenläufigkeit mit SQL Server testen.
- Accounts-Tests müssen ausgeglichene Buchungen, Rollback, parallele Transfers,
  Eigentümerprüfung und Wiederholungen mit demselben Idempotenzschlüssel abdecken.
- Architekturtests können später unerlaubte Referenzen zwischen Services und
  zwischen Schichten verhindern.

Nur synthetische Testdaten verwenden. Testausgaben und Coverage-Dateien werden
nicht versioniert.
