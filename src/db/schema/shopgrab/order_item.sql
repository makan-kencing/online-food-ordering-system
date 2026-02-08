CREATE TABLE order_item
(
    id                    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id              INT REFERENCES "order" (id)      NOT NULL,
    product_id            INT REFERENCES product (id)      NOT NULL,
    product_feature_id    INT REFERENCES product_feature (id),
    feature_order_item_id INT REFERENCES order_item (id), -- used to denote the order line item the feature is applied to
    quantity              INT CHECK ( quantity > 0 )       NOT NULL,
    unit_price            DECIMAL CHECK ( unit_price > 0 ) NOT NULL,
    remarks               VARCHAR(50),
    CHECK ( product_feature_id IS NULL = feature_order_item_id IS NULL )
);