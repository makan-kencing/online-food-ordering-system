CREATE TABLE voucher
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50)                         NOT NULL,
    description VARCHAR(200)                        NOT NULl,
    usage_limit INT CHECK ( usage_limit > 0 ),
    from_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date   TIMESTAMP CHECK ( thru_date > from_date )
);