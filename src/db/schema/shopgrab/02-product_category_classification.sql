CREATE TABLE product_category_classification
(
    product_id          INT REFERENCES product (id),
    product_category_id INT REFERENCES product_category (id),
    from_date           TIMESTAMP             NOT NULL,
    thru_date           TIMESTAMP,
    is_primary          BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY (product_id, product_category_id),
    CHECK ( thru_date is null or thru_date > from_date )
);

-- TODO: Create trigger for ensuring only one is_primary flag for each product AND automatically assign primary if none