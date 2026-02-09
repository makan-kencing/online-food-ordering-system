CREATE DOMAIN order_type AS ENUM
(
   DELIVERY,
   PICKUP
);

CREATE TABLE "order"
(
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id  INT REFERENCES member (id)          NOT NULL,
    ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    order_type order_type                          NOT NULL
);