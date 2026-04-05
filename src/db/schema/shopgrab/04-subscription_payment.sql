create table subscription_payment
(
    monthly_subscription_id INT REFERENCES monthly_subscription (id),
    payment_id              INT REFERENCES payment (id),
    status                  VARCHAR(20),
    PRIMARY KEY (monthly_subscription_id, payment_id)
);
