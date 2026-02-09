CREATE TABLE member_address
(
    member_id  INT REFERENCES member (id),
    address_id INT REFERENCES address (id) UNIQUE,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY (member_id, address_id)
);

-- TODO: Create trigger for ensuring only one is_primary flag for each member AND automatically assign primary if none