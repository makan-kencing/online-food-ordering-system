CREATE DOMAIN adjustment_type AS ENUM
(
    DISCOUNT,
    SURCHARGE,
    SALES_TAX,
    SHIPPING,
    FEE,
    MISCELLANEOUS
);

CREATE TABLE order_item_adjustment
(
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        INT REFERENCES "order" (id) NOT NULL,
    order_item_id   INT REFERENCES order_item (id),
    adjustment_type adjustment_type             NOT NULL,
    amount          DECIMAL CHECK ( amount > 0 ),
    percentage      DECIMAL(5, 4) CHECK ( percentage > 0 AND percentage < 1 ),
    CHECK ( amount IS NULL != percentage IS NULL )
);