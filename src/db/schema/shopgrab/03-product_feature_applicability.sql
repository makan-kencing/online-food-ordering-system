CREATE DOMAIN applicability_type AS ENUM
(
    REQUIRED,
    STANDARD,
    OPTIONAL,
    SELECTABLE
);

CREATE TABLE product_feature_applicability
(
    product_id         INT REFERENCES product (id),
    product_feature_id INT REFERENCES product_feature (id),
    feature_type       applicability_type NOT NULL,
    from_date          TIMESTAMP          NOT NULL,
    thru_date          TIMESTAMP CHECK ( thru_date > from_date ),
    PRIMARY KEY (product_id, product_feature_id)
);