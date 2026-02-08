CREATE TABLE order_value
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_amount DECIMAL NOT NULL CHECK ( from_amount > 0 ),
    thru_amount DECIMAL CHECK ( thru_amount > from_amount )
);