CREATE TABLE delivery
(
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            INT REFERENCES "order" (id)           NOT NULL,
    address_id          INT REFERENCES address (id)         NOT NULL,
    vendor_id           INT REFERENCES delivery_vendor (id) NOT NULL,
    ordered_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    estimated_arrive_at TIMESTAMP                           NOT NULL
);
