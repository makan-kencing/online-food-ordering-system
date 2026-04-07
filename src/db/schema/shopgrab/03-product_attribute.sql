CREATE TABLE product_attribute
(
    product_id               INT REFERENCES product (id),
    product_feature_group_id INT REFERENCES product_feature_group (id),
    PRIMARY KEY (product_id, product_feature_group_id)
);
