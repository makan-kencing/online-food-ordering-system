CREATE TABLE restaurant
(
    id                    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code                  VARCHAR(10) UNIQUE                  NOT NULL,
    name                  VARCHAR(50)                         NOT NULL,
    description           VARCHAR(200)                        NOT NULL,
    introduction_date     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    image_url             VARCHAR(2083),
    opening_hour          INTERVAL DAY(0) TO SECOND(0)        NOT NULL,
    closing_hour          INTERVAL DAY(0) TO SECOND(0)        NOT NULL,
    is_temporarily_closed BOOLEAN   DEFAULT FALSE             NOT NULL,
    address_id            INT REFERENCES address (id)         NOT NULL
);