CREATE TABLE member
(
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username   VARCHAR(50),
    email      VARCHAR(254)                        NOT NULL, -- max length defined in RFC 3696 https://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);