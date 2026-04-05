-- Queries - 1
-- Category Performance per Restaurant, it's calculating the total number of items 
-- and the number of currently available items in each category
-- (if available items are lower than total items, it could mean that category is lacking ingredient)
CREATE OR REPLACE VIEW restaurant_category_performance AS
SELECT
    r.id AS restaurant_id,
    r.name AS restaurant_name,
    mig.name AS category,
    COUNT(mi.product_id) AS total_items,
    SUM(CASE WHEN mi.is_unavailable = FALSE THEN 1 ELSE 0 END) AS available_items
FROM restaurant r
         JOIN menu_item mi ON r.id = mi.restaurant_id
         JOIN menu_item_group mig ON mi.group_id = mig.id
GROUP BY r.id, r.name, mig.name;

/*SELECT * FROM restaurant_category_performance
ORDER BY restaurant_name, total_items DESC;*/

-- Queries - 2 
-- Product performance per feedback, to check which product have low rating or many reported issues
CREATE OR REPLACE VIEW product_feedback_performance AS
SELECT
    p.id AS product_id,
    p.name AS product_name,
    COUNT(f.id) AS total_feedbacks,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(CASE WHEN f.status = 'REPORTED' THEN 1 ELSE 0 END) AS reported_feedbacks
FROM product p
         LEFT JOIN order_item oi ON p.id = oi.product_id
         LEFT JOIN feedback f ON oi.id = f.order_item_id
GROUP BY p.id, p.name;

/*SELECT * FROM product_feedback_performance
    ORDER BY product_name;*/

-- Procedure - 1
-- Add menu item
CREATE OR REPLACE PROCEDURE proc_add_menu_item (
    p_product_name    IN VARCHAR2,
    p_group_name      IN VARCHAR2,
    p_restaurant_id   IN NUMBER
) AS
    v_product_id  INT;
    v_group_id    INT;
    v_count       NUMBER;
BEGIN
    SELECT id INTO v_product_id
    FROM product
    WHERE name = p_product_name;

    SELECT id INTO v_group_id
    FROM menu_item_group
    WHERE name = p_group_name;

    SELECT COUNT(*)
    INTO v_count
    FROM menu_item
    WHERE product_id = v_product_id
      AND restaurant_id = p_restaurant_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Menu item already exists in this restaurant.');
    END IF;
    
    INSERT INTO menu_item (
        product_id,
        restaurant_id,
        group_id,
        is_unavailable,
        from_date
    ) VALUES (
                 v_product_id,
                 p_restaurant_id,
                 v_group_id,
                 FALSE,
                 CURRENT_TIMESTAMP
             );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Menu item successfully added.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Product or group not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
    
-- EXEC proc_add_menu_item('Ice Cream Sundae', 'Pizzas', 3);
-- COMMIT;

/*BEGIN
    proc_add_menu_item('Ice Cream Sundae', 
                       'Pizzas', 
                       3);
END;
/*/

-- Procedure - 2
-- Add order item feedback (image)
CREATE OR REPLACE PROCEDURE proc_add_feedback_image (
    p_feedback_id IN feedback.id%TYPE,
    p_image_url   IN VARCHAR2
) AS
    v_exists      NUMBER;
    v_image_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_exists
    FROM feedback
    WHERE id = p_feedback_id;

    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Feedback ID does not exist.');
    END IF;

    SELECT COUNT(*)
    INTO v_image_count
    FROM feedback_image
    WHERE feedback_id = p_feedback_id;

    IF v_image_count >= 3 THEN
        RAISE_APPLICATION_ERROR(-20002, 'This feedback already has 3 images. Cannot add more.');
    END IF;

    INSERT INTO feedback_image (
        feedback_id,
        image_url,
        uploaded_at
    ) VALUES (
                 p_feedback_id,
                 p_image_url,
                 CURRENT_TIMESTAMP
             );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--- Feedback Image Added ---');
    DBMS_OUTPUT.PUT_LINE('Feedback ID: ' || p_feedback_id);
    DBMS_OUTPUT.PUT_LINE('Image URL  : ' || p_image_url);
    DBMS_OUTPUT.PUT_LINE('Current Time: ' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS'));

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

/*BEGIN
    proc_add_feedback_image(1, 'test.png');
end;
/
commit;*/

-- Trigger - 1
-- Ensure each order items has zero or one feedback rating
CREATE OR REPLACE TRIGGER trg_one_feedback_per_order_item
    BEFORE INSERT ON feedback
    FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM feedback
    WHERE order_item_id = :NEW.order_item_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Only one feedback is allowed per order item.');
    END IF;
END;
/

-- Trigger - 2
-- Ensure each feedback only has a limit of 3 feedback images
CREATE OR REPLACE TRIGGER trg_feedback_image_limit
    BEFORE INSERT ON feedback_image
    FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM feedback_image
    WHERE feedback_id = :NEW.feedback_id;

    IF v_count >= 3 THEN
        RAISE_APPLICATION_ERROR(-20002, 'A feedback can have a maximum of 3 images.');
    END IF;
END;
/

--Report - 1 
--Each restaurant menu with menu item data
CREATE OR REPLACE PROCEDURE proc_menu_detailed_report (p_restaurant_id IN NUMBER DEFAULT NULL) IS
    v_line_width CONSTANT NUMBER := 120;
    v_item_count NUMBER;

    CURSOR cur_restaurants IS
        SELECT *
        FROM restaurant
        WHERE p_restaurant_id IS NULL OR id = p_restaurant_id
        ORDER BY name;

    CURSOR cur_groups (p_restaurant NUMBER) IS
        SELECT g.id, g.name
        FROM menu_item_group g
                 JOIN menu_item m ON m.group_id = g.id
        WHERE m.restaurant_id = p_restaurant
        GROUP BY g.id, g.name
        ORDER BY g.name;

    CURSOR cur_items (p_restaurant NUMBER, p_group NUMBER) IS
        SELECT mi.product_id, p.name AS product_name, mi.is_unavailable,
               mi.from_date, mi.thru_date
        FROM menu_item mi
                 JOIN product p ON mi.product_id = p.id
        WHERE mi.restaurant_id = p_restaurant
          AND mi.group_id = p_group
        ORDER BY p.name;

    rec_restaurant cur_restaurants%ROWTYPE;
    rec_group cur_groups%ROWTYPE;
    rec_item cur_items%ROWTYPE;

BEGIN
    --Header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('MENU ITEM DETAILED REPORT', v_line_width/2 + 15));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('');

    OPEN cur_restaurants;
    LOOP
        FETCH cur_restaurants INTO rec_restaurant;
        EXIT WHEN cur_restaurants%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Restaurant: ' || rec_restaurant.name || ' (' || rec_restaurant.code || ')');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

        OPEN cur_groups(rec_restaurant.id);
        LOOP
            FETCH cur_groups INTO rec_group;
            EXIT WHEN cur_groups%NOTFOUND;

            SELECT COUNT(*) INTO v_item_count
            FROM menu_item
            WHERE restaurant_id = rec_restaurant.id
              AND group_id = rec_group.id;

            DBMS_OUTPUT.PUT_LINE('Menu Item Group: ' || rec_group.name || ' (' || v_item_count || ' items)');
            DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

            DBMS_OUTPUT.PUT_LINE(RPAD('ITEM NAME', 40) || RPAD('AVAILABLE', 10) || RPAD('FROM DATE', 25) || RPAD('THRU DATE', 25));
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

            OPEN cur_items(rec_restaurant.id, rec_group.id);
            LOOP
                FETCH cur_items INTO rec_item;
                EXIT WHEN cur_items%NOTFOUND;

                DBMS_OUTPUT.PUT_LINE(
                        RPAD(rec_item.product_name, 40) ||
                        RPAD(CASE WHEN rec_item.is_unavailable THEN 'No' ELSE 'Yes' END, 10) ||
                        RPAD(TO_CHAR(rec_item.from_date, 'YYYY-MM-DD HH24:MI'), 25) ||
                        RPAD(CASE WHEN rec_item.thru_date IS NULL THEN 'N/A' ELSE TO_CHAR(rec_item.thru_date, 'YYYY-MM-DD HH24:MI') END, 25)
                );
            END LOOP;
            CLOSE cur_items;

            DBMS_OUTPUT.PUT_LINE('‎ ‎ ‎ ‎ ‎ '); -- this is invisible character cuz some reason putting " " doesn't print a blank line for me
        END LOOP;
        CLOSE cur_groups;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    CLOSE cur_restaurants;

    -- Footer
    DBMS_OUTPUT.PUT_LINE(LPAD('END OF MENU ITEM DETAILED REPORT', v_line_width/2 + 10));
    DBMS_OUTPUT.PUT_LINE('');
END;
/

commit;

--Testing for trigger 1
/*
CREATE OR REPLACE PROCEDURE proc_add_order_item_feedback(
    p_order_item_id IN INT,
    p_rating        IN INT,
    p_content       IN VARCHAR2
)
AS
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists
    FROM order_item
    WHERE id = p_order_item_id;

    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Order Item ID does not exist.');
    END IF;

    IF p_rating < 1 OR p_rating > 10 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Rating must be between 1 and 10.');
    END IF;

    INSERT INTO feedback(order_item_id, rating, content)
    VALUES (p_order_item_id, p_rating, p_content);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Feedback added successfully for Order Item ID: ' || p_order_item_id);
END;
/

BEGIN
    proc_add_order_item_feedback(6, '', 'This product is great!');
end;
/
COMMIT;*/
