CREATE TABLE menu_item_group
(
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL,
    description VARCHAR(200) NOT NULL
);