CREATE TABLE monthly_subscription
(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    membership_id INT REFERENCES membership (id)            NOT NULL,
    member_id     INT REFERENCES member (id)                NOT NULL,
    from_date     TIMESTAMP DEFAULT CURRENT_TIMESTAMP       NOT NULL,
    thru_date     TIMESTAMP CHECK ( thru_date > from_date ) NOT NULL,
    payment_id    INT REFERENCES payment (id)               NOT NULL
);

-- TODO: trigger to check dont have overlapping membership duration