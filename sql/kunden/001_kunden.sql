CREATE TABLE kunde (
    id     bigint PRIMARY KEY,
    name   text   NOT NULL
);

INSERT INTO kunde (id, name) VALUES
    (1, 'Volker Habicht'),
    (2, 'Sudaman Kumar'),
    (3, 'Renaldo Goldberg');