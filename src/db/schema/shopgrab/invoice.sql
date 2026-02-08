CREATE TABLE invoice
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    INT REFERENCES "order" (id)         NOT NULL,
    payment_id  INT REFERENCES payment (id)         NOT NULL,
    invoiced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    amount      DECIMAL CHECK ( amount > 0 ) NOT NULL
);