# ADR 0003: Row Level Security on Gehalt ohne Force

  Status: angenommen
## Kontext 
die gehalts tabelle ist unsere sensibelste tabelle diese möchte ich entsprechend schützen. force level security würde für den owner keine gehaltsdaten mehr einlesbar machen.
## Optione
FORCE ROW LEVEL SECURITY aktivieren oder deaktivieren
Wenn wir aktivieren eine eigene Policy für den Owner jeweils der datenbanken anlegen ist wichtig.
## Entscheidung
kein FORCE auf RLS weil gehalt_owner ist eine nologin gruppe und die app verbindet sich über den backend login in die gehalt_rw bzw analyst in die gehalt_ro gruppe. kein app login ist mitglied auf owner.
## Konsequenzen   
gehalts_owner sieht alle Daten und gehalts_owner kann später für migration von gehaltsdaten machen weil wenn wir backfillen wollen wollen wir das entsprechend über alle kunden machen nicht nur die welche die verbunden app. instanz sieht. die konsequenz ist das alle update und deletes alle kunden trifft die in der where klausel sind außerdem with check wird nicht geprüft und man könnte kunde_id umschreiben... 
set_config akzeptiert $1, SET nicht, damit wird SQL Injection und String Concat verhindert. Außerdem ist set_config mit true als drittem Parameter wie SET LOCAL und gilt nur bis zum Ende der Transaktion. Mit einem normalen SET gilt die Variable für die ganze Session, hängt bei pgxpool ohne Reset an der Verbindung, und die nächste Anfrage, die dieselbe Verbindung aus dem Pool bekommt, sieht dann die Gehälter von Kunde 1.

## Ursprungsfragen claudinho
- a) Wie hast du dich bei FORCE ROW LEVEL SECURITY entschieden? Was würde ohne FORCE passieren, wenn eine Migration als gehalt_owner Daten anfasst?

- b) Das Go-Backend nutzt später einen Connection Pool (pgxpool). Warum muss es set_config(…, true) innerhalb einer Transaktion verwenden statt SET app.kunde_id = …? Was passiert sonst mit der nächsten Anfrage, die dieselbe Verbindung aus dem Pool bekommt?