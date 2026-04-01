CREATE TABLE product_feature_group_field
(
    product_feature_group_id INT REFERENCES product_feature_group (id),
    product_feature_id       INT REFERENCES product_feature (id),
    PRIMARY KEY (product_feature_group_id, product_feature_id)
);