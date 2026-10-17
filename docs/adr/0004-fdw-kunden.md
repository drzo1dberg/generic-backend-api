# ADR 0004: Kundendaten in versicherung über postgres_fdw

Status: angenommen

## Kontext
versicherung braucht zu den verträgen den kundennamen aus kunden. über datenbankgrenzen gibt es aber keinen JOIN (siehe ADR 0001), eine verbindung gehört immer zu genau einer datenbank. postgres_fdw macht versicherung selbst zum client von kunden, die kunden-tabelle taucht dann in versicherung als foreign table auf.

## Optionen
1. foreign table in public oder in einem eigenen schema kunden_remote
2. user mapping für PUBLIC oder pro rolle. ein mapping für eine gruppe (z.b. versicherung_rw) geht nicht, postgres sucht das mapping nur für den aktuellen user oder PUBLIC und vererbt nicht über mitgliedschaften (getestet: "user mapping not found")
3. JOIN per FDW in der datenbank oder im go-backend

## Entscheidung
- foreign table landet in public. die default privileges aus ADR 0002 greifen damit automatisch, backend und analyst bekommen SELECT ohne extra grants. eigenes schema wäre sauberer (siehe konsequenzen) aber für eine einzige tabelle im lernrepo ist public ok, umstieg sind 3 zeilen sql.
- user mapping pro rolle (versicherung_owner für den import, backend und analyst für abfragen), alle drei melden sich in kunden als fdw_kunden an. fdw_kunden ist nur in kunden_ro, kleinster blast radius. pro rolle statt PUBLIC weil eine neue login rolle dann erst mal keinen zugriff auf kunden hat bis wir es bewusst eintragen.
- FDW für lesende abfragen und auswertungen (analyst). JOINs im heißen pfad vom backend macht später go.

## Konsequenzen
- backend hat durch die default privileges auch INSERT/UPDATE/DELETE auf die foreign table. die werden über den FDW in kunden ausgeführt und erst dort abgelehnt weil fdw_kunden nur ro ist (getestet: "permission denied for table kunde", CONTEXT: remote SQL command). es gibt also nur eine sperre statt zwei. mit eigenem schema und nur GRANT SELECT wären es zwei.
- kunde sieht in versicherung aus wie eine lokale tabelle. wer die abfrage liest sieht nicht dass da eine zweite verbindung dahinter hängt.
- der JOIN von vertrag und kunde läuft lokal in versicherung (merge join), das remote sql ist nur "SELECT id, name FROM public.kunde" ohne WHERE. bei jedem JOIN wird also die komplette kunden tabelle rübergeholt, bei 50.000 kunden jedes mal 50.000 zeilen. ein WHERE nur auf kunde (z.b. name = 'Ben') wird dagegen in kunden ausgeführt (pushdown).
- keine fremdschlüssel über datenbanken: vertrag.kunde_id kann auf einen kunden zeigen den es nicht gibt, niemand prüft das.
- die foreign table ist ein schnappschuss der spalten zum zeitpunkt vom import. neue spalte in kunde → in versicherung erst nach erneutem IMPORT FOREIGN SCHEMA sichtbar.
- versicherung hängt jetzt von kunden ab: make sql muss kunden vor versicherung einspielen (passt gerade nur alphabetisch), und ist kunden kaputt schlagen JOINs in versicherung fehl.
- schreiben über beide datenbanken ist nicht atomar. postgres_fdw macht kein echtes two-phase commit, für geschäftsvorgänge über beide datenbanken braucht das backend eine andere lösung.
- localhost verlangt jetzt passwort (scram-sha-256), sonst lehnt postgres_fdw nicht-superuser ab. auf azure sowieso so.
