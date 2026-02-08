CREATE TABLE membership
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50)                 NOT NULL,
    description VARCHAR(200)                NOT NULL,
    price       DECIMAL CHECK ( price > 0 ) NOT NULL
);