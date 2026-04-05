CREATE DOMAIN status AS ENUM
(
    ACTIVE,
    UPGRADED
);

create table subscription_payment
(
    monthly_subscription_id INT REFERENCES monthly_subscription (id),
    payment_id              INT REFERENCES payment (id),
    status                 status not null ,
    PRIMARY KEY (monthly_subscription_id, payment_id)
);
