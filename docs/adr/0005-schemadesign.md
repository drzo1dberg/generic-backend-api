# ADR 0005: Schemadesign, Typen und Constraints

Status: angenommen

## Kontext
bis schritt 1 waren die tabellen absichtlich minimal. jetzt soll die datenbank selbst falsche daten ablehnen und nicht erst das go-backend. das backend ist nur ein weg wie daten reinkommen, migrationen, psql oder ein zweiter dienst sind andere. ein constraint gilt für alle.
nebenbei: bezeichner im code (datenbanken, rollen, tabellen, spalten) sind ab jetzt englisch: kunden → customer, gehalt → salary, versicherung → contract. doku und kommentare bleiben deutsch. ADR 0001–0004 nennen noch die alten namen, die bleiben so, ADRs sind momentaufnahmen.

## Optionen
- ids: bigint identity, uuidv7 (neu in pg 18), uuid v4
- geld: numeric, float, money
- zeit: date, timestamptz, timestamp ohne tz
- "monatserster" prüfen: date_trunc oder extract
- net_salary: generated VIRTUAL oder STORED
- vertragsart: CHECK IN (...), ENUM oder lookup tabelle mit FK
- vertragslaufzeit: zwei date spalten + EXCLUDE oder eine daterange spalte + WITHOUT OVERLAPS

## Entscheidung
- ids sind bigint GENERATED ALWAYS AS IDENTITY. nur customer vergibt kunden-ids, wir brauchen keine weltweite eindeutigkeit. customer_id steht in jeder zeile von salary und contract, bei millionen gehaltszeilen sind 8 statt 16 byte pro zeile (und pro index) spürbar. uuidv7 nehmen wir wenn go ids selbst erzeugen soll oder mehrere systeme kunden anlegen. ALWAYS statt BY DEFAULT damit keiner eigene ids reinschreibt die später mit der sequenz kollidieren.
- geld ist numeric(p,s). float rechnet binär (0.1 + 0.2 = 0.30000000000000004), money hängt an lc_monetary vom server (bei uns kam $59.97 raus).
- date für kalendertage (geburtsdatum, gehaltsmonat, vertragslaufzeit), timestamptz für zeitpunkte (created_at). timestamp ohne tz nehmen wir nicht, "14:00" ohne zeitzone ist mehrdeutig.
- email check mit zeichenklassen ([[:alnum:]], [[:alpha:]]) statt A-Za-z. damit gehen umlaute (jürgen@müller.de) und auch andere schriften (kyrillisch). eindeutig ist die email über einen unique index auf lower(email), nicht über UNIQUE (email), sonst wären anna@ und ANNA@ zwei kunden.
- monatserster wird mit extract(day FROM month) = 1 geprüft. date_trunc gibt es nicht für date, postgres nimmt dann die timestamptz version und die ist nur stable (hängt an der zeitzone der session). extract auf date ist immutable. aus demselben grund kein current_date in einem CHECK (z.b. birthdate <= current_date), "nicht in der zukunft" prüft das backend.
- net_salary ist VIRTUAL (in pg 18 standard). kostet 0 byte, wird beim lesen gerechnet. VIRTUAL kann man nicht indizieren ("indexes on virtual generated columns are not supported"), brauchen wir aber nicht, gefragt wird nach kunde und nicht nach netto.
- vertragsarten sind eine lookup tabelle contract_type mit FK. neue art ist ein INSERT und keine schemaänderung, eine art kann später eigene spalten bekommen. ENUM werte kann man nicht mehr entfernen. code ist der stabile schlüssel für programme (go nutzt 'pension', nie die id), name ist der text für menschen. contract_rw darf contract_type nur lesen (REVOKE nach den default privileges).
- laufzeit ist eine daterange spalte validity mit UNIQUE (customer_id, contract_type_id, validity WITHOUT OVERLAPS). "läuft heute?" ist dann validity @> current_date statt der fehleranfälligen start/end/IS NULL bedingung. ende vor anfang geht technisch gar nicht.
- constraints über mehrere spalten stehen an der tabelle und haben eigene namen (salary_deduction_less_equal_gross, salary_once_per_month, contract_has_no_overlap, contract_validity_has_start). im fehler steht dann sofort was verletzt wurde.

## Konsequenzen
- ids haben lücken. jeder fehlgeschlagene INSERT verbraucht eine nummer aus der sequenz, die wird nie zurückgerollt. ist absicht, sonst müssten sich alle parallelen transaktionen anstellen. lückenlose nummern (z.b. rechnungsnummer) bräuchten eine eigene lösung.
- die email prüfung hängt an LC_CTYPE der datenbank (bei uns en_US.utf8). was als buchstabe zählt und dass Ü zu ü gehört entscheidet die locale. auf azure muss das auch so sein. die prüfung ist absichtlich grob, ob eine adresse existiert zeigt nur eine bestätigungsmail.
- wollen wir später nach net_salary filtern oder sortieren müssen wir auf STORED wechseln (kostet platz pro zeile).
- validity braucht einen eigenen CHECK gegen 'empty' und gegen ranges ohne anfang ('(,2030-01-01)'), die gibts bei zwei date spalten nicht.
- daterange ist immer [) normalisiert: ende gehört nicht dazu. vertrag bis 2023-01-01 und folgevertrag ab 2023-01-01 überlappen nicht. '[2020-01-01,2020-12-31]' wird automatisch zu [2020-01-01,2021-01-01).
- WITHOUT OVERLAPS ist intern ein GiST index, braucht also btree_gist (läuft per terraform in extensions.tf, auf azure muss es auf die allowlist azure.extensions). im fehler steht trotzdem "exclusion constraint", darunter ist es dasselbe wie EXCLUDE.
- range typen sind postgres spezifisch. go mappt das mit pgtype.Range[pgtype.Date], andere tools (bi, orms) können damit eventuell nichts anfangen.
- customer_id in salary und contract hat weiterhin keinen FK (andere datenbank, siehe ADR 0004). contract_type_id hat einen, weil die lookup tabelle in derselben datenbank liegt. eine benutzte vertragsart kann man nicht löschen.
- testdaten mit lookup werden per VALUES + JOIN auf code eingefügt. tippfehler im code lassen die zeile still wegfallen, also nachzählen. ORDER BY im INSERT ... SELECT damit die ids bei jedem aufbau gleich sind (wichtig für schritt 3, gleicher seed = gleiche prüfsumme).
- make sql spielt in fester reihenfolge customer, salary, contract ein (SQL_DBS im makefile), weil contract per FDW aus customer importiert. alphabetisch wäre contract zuerst und der import geht ins leere.

## Ursprungsfragen claudinho
- a) Warum bigint Identity und nicht uuidv7 für customer.id? Wann würdest du wechseln?
- b) Warum gehört weder current_date noch date_trunc in einen CHECK? Woran erkennt man, ob eine Funktion in einem CHECK sicher ist?
- c) net_salary als VIRTUAL oder STORED: was kostet was, und wann würdest du umstellen?
- d) Lookup-Tabelle, ENUM oder CHECK IN für die Vertragsart?
- e) Laufzeit als zwei Spalten mit EXCLUDE oder als daterange mit WITHOUT OVERLAPS: was gewinnst du, was verlierst du?
