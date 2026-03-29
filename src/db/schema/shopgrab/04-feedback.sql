CREATE TABLE feedback
(
    order_item_id INT UNIQUE REFERENCES order_item (id) PRIMARY KEY,
    content       VARCHAR(200) NOT NULL,
    rating        INT CHECK ( 0 < rating AND rating <= 10 ) -- out of 10
);