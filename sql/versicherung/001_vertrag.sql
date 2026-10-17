CREATE TABLE vertrag (
    id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kunde_id bigint        NOT NULL,
    art      text          NOT NULL
);

INSERT INTO vertrag (kunde_id, art) VALUES
    (1, 'Haftpflicht'),
    (1, 'Rente'),
    (2, 'Kfz'),
    (3, 'Rechtsschutz'),
    (3, 'Hausrat'),
    (3, 'BU');

IMPORT FOREIGN SCHEMA public LIMIT TO (kunde)
    FROM SERVER kunden_srv
    INTO public;
