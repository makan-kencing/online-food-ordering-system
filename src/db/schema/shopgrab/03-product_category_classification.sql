CREATE TABLE product_category_classification
(
    product_id          INT REFERENCES product (id),
    product_category_id INT REFERENCES product_category (id),
    from_date           TIMESTAMP             NOT NULL,
    thru_date           TIMESTAMP,
    is_primary          BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY (product_id, product_category_id),
    CHECK ( thru_date is null or thru_date > from_date )
);

CREATE INDEX idx_category_classification_dates ON product_category_classification(from_date, thru_date);

-- Create trigger for ensuring only one is_primary flag for each product AND automatically assign primary if none
CREATE OR REPLACE TRIGGER trg_single_primary_category
    FOR INSERT OR UPDATE ON product_category_classification
    COMPOUND TRIGGER

    TYPE product_check_t IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_products_to_check product_check_t;
    v_idx PLS_INTEGER := 0;

BEFORE EACH ROW IS
BEGIN
    IF INSERTING AND :NEW.is_primary = FALSE THEN
        DECLARE
            v_has_primary NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_has_primary
            FROM product_category_classification
            WHERE product_id = :NEW.product_id
              AND is_primary = TRUE
              AND (thru_date IS NULL OR thru_date > CURRENT_TIMESTAMP);

            IF v_has_primary = 0 THEN
                :NEW.is_primary := TRUE;
            END IF;
        END;
    END IF;

    IF :NEW.is_primary = TRUE THEN
        v_idx := v_idx + 1;
        v_products_to_check(v_idx) := :NEW.product_id;
    END IF;

    IF :NEW.from_date IS NULL THEN
        :NEW.from_date := CURRENT_TIMESTAMP;
    END IF;
END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_primary_count NUMBER;
    BEGIN
        FOR i IN 1..v_idx LOOP
                SELECT COUNT(*) INTO v_primary_count
                FROM product_category_classification
                WHERE product_id = v_products_to_check(i)
                  AND is_primary = TRUE
                  AND (thru_date IS NULL OR thru_date > CURRENT_TIMESTAMP);

                IF v_primary_count > 1 THEN
                    RAISE_APPLICATION_ERROR(-20020,
                                            'Product ' || v_products_to_check(i) || ' has multiple primary categories.');
                END IF;
            END LOOP;
    END AFTER STATEMENT;

    END trg_single_primary_category;
/
