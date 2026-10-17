CREATE TABLE contract_type (
    id       smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code     text     NOT NULL UNIQUE CHECK (code ~ '^[a-z_]+$'),
    name     text     NOT NULL
);

REVOKE INSERT, UPDATE, DELETE ON contract_type FROM contract_rw;

INSERT INTO contract_type (code, name) VALUES
    ('liability', 'Haftpflichtversicherung'),
    ('pension', 'Rentenversicherung'),
    ('car', 'Kfz-Versicherung'),
    ('legal', 'Rechtsschutzversicherung'),
    ('household', 'Hausratversicherung'),
    ('disability', 'Berufsunfähigkeitsversicherung');

CREATE TABLE contract (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id        bigint NOT NULL,
    contract_type_id   smallint NOT NULL REFERENCES contract_type (id),
    validity           daterange NOT NULL,
    monthly_premium    numeric(10,2) NOT NULL CHECK (monthly_premium > 0),

    CONSTRAINT contract_validity_has_start
        CHECK (NOT isempty(validity) AND NOT lower_inf(validity)),
    CONSTRAINT contract_has_no_overlap
        UNIQUE (customer_id, contract_type_id, validity WITHOUT OVERLAPS)
);

INSERT INTO contract (customer_id, contract_type_id, validity, monthly_premium)
  SELECT v.customer_id, t.id, v.validity, v.monthly_premium
  FROM (VALUES
      (1, 'liability',  daterange('2020-01-01', NULL),         6.90),
      (1, 'pension',    daterange('2018-04-01', NULL),       150.00),
      (2, 'disability', daterange('2021-07-01', '2051-07-01'), 72.40),
      (3, 'household',  daterange('2015-01-01', '2023-01-01'),  9.80),
      (3, 'household',  daterange('2023-01-01', NULL),         12.10)
  ) AS v(customer_id, code, validity, monthly_premium)
  JOIN contract_type t ON t.code = v.code
  ORDER BY v.customer_id, lower(v.validity);

IMPORT FOREIGN SCHEMA public LIMIT TO (customer)
    FROM SERVER customer_srv
    INTO public;
