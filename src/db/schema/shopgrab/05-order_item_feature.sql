CREATE TABLE order_item_feature
(
    product_feature_id INT REFERENCES product_feature (id),
    order_item_id      INT REFERENCES order_item (id), -- used to denote the order line item the feature is applied to
    quantity           INT CHECK ( quantity > 0 )       NOT NULL,
    unit_price         DECIMAL CHECK ( unit_price >= 0 ) NOT NULL,
    remarks            VARCHAR(50),
    PRIMARY KEY (product_feature_id, order_item_id)
);
