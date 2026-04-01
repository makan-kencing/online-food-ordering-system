CREATE TABLE product_feature_group
(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(50)                NOT NULL,
    min           INT DEFAULT 0              NOT NULL,
    max           INT,
    created_by_id INT REFERENCES member (id) NOT NULL
);