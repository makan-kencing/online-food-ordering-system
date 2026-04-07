CREATE TABLE menu_item
(
    product_id     INT REFERENCES product (id),
    restaurant_id  INT REFERENCES restaurant (id),
    group_id       INT REFERENCES menu_item_group (id),
    is_unavailable BOOLEAN   DEFAULT FALSE             NOT NULL,
    from_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date      TIMESTAMP,
    PRIMARY KEY (product_id, restaurant_id),
    CHECK ( thru_date is null or thru_date > from_date )
);
