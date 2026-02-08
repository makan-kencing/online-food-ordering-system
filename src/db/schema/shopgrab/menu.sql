CREATE TABLE menu
(
    product_id     INT REFERENCES product (id),
    restaurant_id  INT REFERENCES restaurant (id),
    category_id    INT REFERENCES menu_category (id),
    is_unavailable BOOLEAN   DEFAULT FALSE             NOT NULL,
    from_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date      TIMESTAMP CHECK ( thru_date > from_date ),
    PRIMARY KEY (product_id, restaurant_id)
);