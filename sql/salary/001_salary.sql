CREATE TABLE salary (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   bigint NOT NULL,
    month         date   NOT NULL CHECK (extract(day FROM month) = 1),
    gross_salary  numeric(12,2) NOT NULL CHECK (gross_salary >= 0),
    deduction     numeric(12,2) NOT NULL CHECK (deduction >= 0),
    net_salary    numeric(12,2) GENERATED ALWAYS AS (gross_salary - deduction) VIRTUAL,

    CONSTRAINT salary_deduction_less_equal_gross CHECK (deduction <= gross_salary),
    CONSTRAINT salary_once_per_month             UNIQUE (customer_id, month)
);


  INSERT INTO salary (customer_id, month, gross_salary, deduction) VALUES
      (1, '2026-07-01', 5500.00, 2050.00),
      (1, '2026-08-01', 5500.00, 2050.00),
      (1, '2026-09-01', 5650.00, 2110.00),
      (2, '2026-07-01', 3100.00, 1010.50),
      (2, '2026-08-01', 3100.00, 1010.50),
      (3, '2026-07-01', 6890.75, 2700.00);

ALTER TABLE salary ENABLE ROW LEVEL SECURITY;

CREATE POLICY salary_rw_only_id_in_request ON salary
FOR ALL
TO salary_rw
USING     (customer_id = NULLIF(current_setting('app.customer_id', true), '')::bigint)
WITH CHECK (customer_id = NULLIF(current_setting('app.customer_id', true), '')::bigint);

CREATE POLICY salary_ro_all on salary
FOR SELECT
TO salary_ro
USING (true);