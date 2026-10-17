CREATE TABLE gehalt (
    id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kunde_id  bigint        NOT NULL,
    monat     date          NOT NULL,
    brutto    numeric(12,2) NOT NULL
);

INSERT INTO gehalt (kunde_id, monat, brutto) VALUES
    (1, '2026-07-01', 5500.00),
    (1, '2026-08-01', 5500.00),
    (1, '2026-09-01', 5650.00),
    (2, '2026-07-01', 3100.00),
    (2, '2026-08-01', 3100.00),
    (2, '2026-09-01', 3100.00),
    (3, '2026-07-01', 6890.75),
    (3, '2026-08-01', 7420.00),
    (3, '2026-09-01', 6890.75);

ALTER TABLE gehalt ENABLE ROW LEVEL SECURITY;

CREATE POLICY gehalt_rw_only_id_in_request ON gehalt
FOR ALL
TO gehalt_rw
USING     (kunde_id = NULLIF(current_setting('app.kunde_id', true), '')::bigint)
WITH CHECK (kunde_id = NULLIF(current_setting('app.kunde_id', true), '')::bigint);

CREATE POLICY gehalt_ro_all on gehalt
FOR SELECT
TO gehalt_ro
USING (true);

RESET ROLE;