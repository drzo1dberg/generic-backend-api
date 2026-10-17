CREATE TABLE customer (
    id              bigint  GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
    firstname       text    NOT NULL CHECK (btrim(firstname) <> ''),
    lastname        text    NOT NULL CHECK (btrim(lastname) <> ''),
    birthdate       date    NOT NULL CHECK (birthdate >= '1900-01-01'),
    email           text    NOT NULL CHECK (email ~ '^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$'),
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX customer_email_uq ON customer (lower(email));

INSERT INTO customer (firstname, lastname, birthdate, email) VALUES
    ('Volker', 'Habicht', '1980-05-15', 'volker.habicht@example.com'),
    ('Sudaman', 'Kumar', '1990-01-01', 'sudaman.kumar@example.com'),
    ('Renaldo', 'Goldberg', '1985-12-25', 'renaldo.goldberg@example.com');