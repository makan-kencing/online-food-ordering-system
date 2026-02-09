CREATE TABLE product_category_hierarchy
(
    parent_category_id INT REFERENCES product_category (id),
    child_category_id  INT REFERENCES product_category (id),
    PRIMARY KEY (parent_category_id, child_category_id)
);