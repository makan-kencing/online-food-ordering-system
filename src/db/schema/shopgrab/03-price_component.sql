CREATE DOMAIN price_type AS ENUM
(
    BASE,
    DISCOUNT,
    SURCHARGE
);

CREATE TABLE price_component
(
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    price_type          price_type                          NOT NULL,
    from_date           TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date           TIMESTAMP CHECK ( thru_date > from_date ),
    description         VARCHAR(200)                        NOT NULL,
    amount              DECIMAL CHECK ( amount > 0 ),
    percentage          DECIMAL(5, 4) CHECK ( percentage > 0 AND percentage < 1 ),
    product_id          INT REFERENCES product (id),
    product_feature_id  INT REFERENCES product_feature (id),
    product_category_id INT REFERENCES product_category (id),
    quantity_break_id   INT REFERENCES quantity_break (id),
    order_value_id      INT REFERENCES order_value (id),
    membership_id       INT REFERENCES membership (id),
    voucher_id          INT REFERENCES voucher (id),
    vendor_id           INT REFERENCES delivery_vendor (id),
    CHECK ( amount IS NULL != percentage IS NULL )
);