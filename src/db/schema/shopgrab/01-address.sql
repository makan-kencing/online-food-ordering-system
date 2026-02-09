CREATE TABLE address
(
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(50) NOT NULL,
    contact_no VARCHAR(15) NOT NULL,
    address_1  VARCHAR(50) NOT NULL,
    address_2  VARCHAR(50),
    address_3  VARCHAR(50),
    city       VARCHAR(50) NOT NULL,
    state      VARCHAR(50) NOT NULL,
    postcode   VARCHAR(10) NOT NULL,
    country    VARCHAR(50) NOT NULl
);