CREATE TABLE payment
(
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_method_id   INT REFERENCES payment_method (id)  NOT NULl,
    paid_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ref_no              VARCHAR(200)                        NOT NULL,
    amount              DECIMAL CHECK ( amount > 0 )        NOT NULL,
    payment_method_date JSON                                NOT NULL
);