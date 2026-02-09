CREATE DOMAIN interaction_type AS ENUM
(
   DEPENDENT,
   INCOMPATIBLE
);

CREATE TABLE product_feature_interaction
(
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feature_a_id     INT REFERENCES product_feature (id) NOT NULL,
    feature_b_id     INT REFERENCES product_feature (id) NOT NULL,
    product_id       INT REFERENCES product (id),
    interaction_type interaction_type                    NOT NULL,
    UNIQUE (feature_a_id, feature_b_id, product_id)
);