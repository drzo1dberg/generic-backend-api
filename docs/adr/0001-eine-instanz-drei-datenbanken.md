# ADR 0001: Eine PostgreSQL-Instanz mit drei Datenbanken

Status: angenommen

## Kontext
Drei Fachbereiche (kunden, gehalt, versicherung). Das Go-Backend greift später auf alle drei zu. Ziel ist Azure Flexible Server; ein Server dort kostet pro Instanz.

## Optionen
- A: eine Instanz, drei Datenbanken
- B: eine Instanz, eine Datenbank, drei Schemas
- C: drei Instanzen

## Entscheidung
A. Harte Grenzen zwischen den Datenbanken (eigene Kataloge, eigenes CONNECT-Recht, keine Cross-DB-JOINs) bei den Kosten einer Instanz. Ein Streaming-Replica kommt später hinzu.

## Konsequenzen
- Rollen sind clusterweit und gelten für alle drei Datenbanken; Rechte werden pro Datenbank vergeben.
- JOINs über Datenbankgrenzen gibt es nicht. Entweder JOINt das Backend in Go, oder postgres_fdw wird eingesetzt (Schritt 1b).
- Für alle drei Datenbanken gelten dieselben Serverparameter, dieselbe Major-Version und dasselbe Backup bzw. PITR. Eine Datenbank allein lässt sich nicht per PITR zurücksetzen.
- Wechsel zu B ist möglich, falls sich zeigt, dass das Backend ständig über Domänen hinweg JOINt.
