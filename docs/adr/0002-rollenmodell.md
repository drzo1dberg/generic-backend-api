 # ADR 0002: Rollenmodell

  Status: angenommen
## Kontext 
ein backend service das in go geschrieben drei datenbanken kunden gehalt und versicherung in postgresql die gehaltsdaten sensibel behandeln
## Optione
 ein login für alles also der backend service consumed einfach über ein login alle datenbanken auf dieser instanz
 ein login PRO datenbank also backend_gehalt, backend_kunden, backend_versicherungen welche die sicherheit erhöhen
## Entscheidung
das backend als login alle drei rw rollen hält ist ein sicherheitsproblem weil ein komprimierter zugang direkt zugang in drei instanzen lässt. die alternative wäre drei logins bzw ein login je Datenbank auf dieser Instanz - wir verringern den Blast radius hiermit also ist der einschlag eines kompromierten zugangs verringert. wir akzeptieren das risiko mit dem hohen blast radius weil das hier ein reines lernrepo ist. 
## Konsequenzen     ← dein a und b + offener Punkt: Migrationsrolle (Schritt 8)

a) _owner hat kein Login weil später wird nur mitglied, die rolle die migrationen ausführt. der hintergrund ist die ALTER DEFAULT PRIVILEGES durch den Owner auf die app rolle erst das erstellen durch den owner erstellt einen grant an die app rolle. der login ist raus weil sich mit so einer rolle die in allen tabellen löschen das ist unsicher per design 

c) das backend als login alle drei rw rollen hält ist ein sicherheitsproblem weil ein komprimierter zugang direkt zugang in drei instanzen lässt. die alternative wäre drei logins bzw ein login je Datenbank auf dieser Instanz - wir verringern den Blast radius hiermit also ist der einschlag eines kompromierten zugangs verringert. wir akzeptieren das risiko mit dem hohen blast radius weil das hier ein reines lernrepo ist.   

## Ursprungsfragen claudinho
 - a) Warum hat <db>_owner kein LOGIN, und wie laufen dann später die Migrationen?
 - b) Was passiert mit den Rechten, wenn pgadmin statt <db>_owner eine Tabelle anlegt?
 - c) backend gehört zu allen drei _rw-Rollen. Ist das ein Sicherheitsproblem? Was wäre die Alternative?
