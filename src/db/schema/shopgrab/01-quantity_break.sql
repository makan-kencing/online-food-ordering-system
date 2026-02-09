CREATE TABLE quantity_break
(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_quantity INT NOT NULL CHECK ( from_quantity > 0 ),
    to_quantity   INT CHECK ( to_quantity > from_quantity )
);