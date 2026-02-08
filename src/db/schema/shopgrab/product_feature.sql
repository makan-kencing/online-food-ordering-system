CREATE TABLE product_feature
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL,
    description VARCHAR(200) NOT NULL,
    category_id INT REFERENCES product_feature_category (id)
);