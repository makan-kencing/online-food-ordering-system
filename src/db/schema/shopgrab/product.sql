CREATE TABLE product
(
    id                INT PRIMARY KEY,
    code              VARCHAR(10) UNIQUE                  NOT NULL,
    name              VARCHAR(50)                         NOT NULL,
    description       VARCHAR(200)                        NOT NULL,
    introduction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    image_url         VARCHAR(2083)
);