# Lösung: Protected Branch Konfiguration wird jetzt automatisch angewendet

## Problem

Die Konfigurationen aus der `.github/settings.yml` für den Protected Branch wurden nicht ausgeführt, weil:

1. Die `settings.yml` Datei war für die **Probot Settings App** (auch bekannt als **Repository Settings App**) konfiguriert
2. Diese GitHub App muss manuell in der Organisation/Repository installiert werden
3. Ohne Installation der App werden die Einstellungen nicht angewendet
4. Die Datei allein macht nichts - sie ist nur eine Konfigurationsdatei

## Lösung

Anstatt auf eine externe GitHub App angewiesen zu sein, wurde ein **GitHub Actions Workflow** erstellt, der die Einstellungen automatisch über die GitHub API anwendet.

### Neue Dateien

1. **`.github/workflows/sync-repo-settings.yml`** - Der neue Workflow
2. **`docs/TestingSettingsSync.md`** - Testanleitung (Englisch)
3. **`docs/LösungProtectedBranch.md`** - Diese Datei

### Geänderte Dateien

1. **`.github/settings.yml`** - Header-Kommentar aktualisiert
2. **`.github/README.md`** - Dokumentation aktualisiert

## Wie funktioniert die Lösung?

Der neue Workflow (`sync-repo-settings.yml`) wird automatisch ausgeführt, wenn:

1. Änderungen an `.github/settings.yml` auf den `main` Branch gepusht werden
2. Der Workflow manuell über die GitHub Actions UI gestartet wird

### Was macht der Workflow?

Der Workflow wendet drei Kategorien von Einstellungen an:

#### 1. Repository-Einstellungen
- Beschreibung und Homepage
- Features (Issues, Projects, Wiki)
- Merge-Optionen (Squash, Rebase)
- Branch-Löschung nach Merge

#### 2. Branch Protection Rules (main Branch)
- Erforderliche Anzahl an Reviews: **1**
- Code Owner Reviews erforderlich: **Ja**
- Stale Reviews automatisch verwerfen: **Ja**
- Status Checks müssen bestehen: **Ja**
- Conversation Resolution erforderlich: **Ja**
- Force Pushes erlauben: **Nein**
- Branch-Löschung erlauben: **Nein**

#### 3. Labels
- Erstellt/aktualisiert alle Labels aus settings.yml
- Inklusive Name, Farbe und Beschreibung

## Vorteile der neuen Lösung

✅ **Keine externe App erforderlich** - Alles läuft über GitHub Actions  
✅ **Automatische Anwendung** - Bei jedem Push zu settings.yml  
✅ **Sofortige Wirkung** - Keine Wartezeit für App-Synchronisation  
✅ **Volle Kontrolle** - Alles ist im Repository Code  
✅ **Audit Trail** - Alle Änderungen sind in Actions sichtbar  
✅ **Kostenlos** - Nutzt GitHub Actions (im Rahmen der Free-Minuten)

## Wie wird es verwendet?

### Automatische Verwendung

1. Änderungen an `.github/settings.yml` vornehmen
2. Commit und Push zu `main` Branch
3. Der Workflow läuft automatisch
4. Einstellungen werden angewendet

### Manuelle Verwendung

1. Zu GitHub Actions navigieren
2. Workflow "Sync Repository Settings" auswählen
3. "Run workflow" klicken
4. Branch `main` auswählen
5. "Run workflow" bestätigen

## Überprüfung

Nach dem Workflow-Lauf überprüfen:

1. **Repository Settings** → General
   - Beschreibung und Homepage korrekt?
   - Features aktiviert/deaktiviert wie gewünscht?

2. **Repository Settings** → Branches → main
   - Branch protection rules aktiv?
   - Required reviews: 1?
   - Code owners reviews required?

3. **Issues** → Labels
   - Alle Labels vorhanden?
   - Farben korrekt?

## Wichtige Hinweise

- Der Workflow benötigt `GITHUB_TOKEN` (automatisch verfügbar)
- Mindestberechtigung: `contents: read`
- Branch protection benötigt Admin-Rechte (automatisch für Workflows)
- Der Workflow ist idempotent (mehrfaches Ausführen = gleiches Ergebnis)

## Nächste Schritte

1. Pull Request mergen
2. Workflow manuell ausführen oder
3. Settings.yml ändern und pushen
4. Verifizieren dass Branch Protection aktiv ist

## Weitere Informationen

- Siehe `docs/TestingSettingsSync.md` für detaillierte Testanweisungen
- Siehe `.github/README.md` für vollständige Dokumentation
- Workflow-Logs in GitHub Actions → Sync Repository Settings
