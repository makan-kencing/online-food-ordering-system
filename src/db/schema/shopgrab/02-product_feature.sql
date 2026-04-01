CREATE TABLE product_feature
(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(50)                NOT NULL,
    code          VARCHAR(200)               NOT NULL,
    created_by_id INT REFERENCES member (id) NOT NULL
);