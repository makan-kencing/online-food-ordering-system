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

-- EXEC proc_add_feedback_image(1, 'test.png');
commit;

-- Trigger - 1
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

commit;

--Report - 1 
--Display a restaurant's menu items revenue (including total revenue and top item revenue)
CREATE OR REPLACE PROCEDURE proc_menu_revenue_report (
    p_restaurant_id IN NUMBER DEFAULT NULL
) IS

    v_line_width CONSTANT NUMBER := 120;

    v_category_total NUMBER := 0;
    v_restaurant_total NUMBER := 0;

    v_top_item_name VARCHAR2(100);
    v_top_item_revenue NUMBER := 0;

    CURSOR cur_restaurants IS
        SELECT id, name, code
        FROM restaurant
        WHERE id = p_restaurant_id
        ORDER BY name;

    CURSOR cur_categories(p_restaurant NUMBER) IS
        SELECT DISTINCT g.id, g.name
        FROM menu_item_group g
                 JOIN menu_item mi ON mi.group_id = g.id
        WHERE mi.restaurant_id = p_restaurant
        ORDER BY g.name;

    CURSOR cur_items(p_restaurant NUMBER, p_group NUMBER) IS
        SELECT
            p.name AS product_name,
            NVL(SUM(oi.quantity * oi.unit_price),0) AS revenue,
            NVL(SUM(oi.quantity),0) AS quantity_sold
        FROM menu_item mi
                 JOIN product p ON mi.product_id = p.id
                 LEFT JOIN order_item oi ON oi.product_id = p.id
                 LEFT JOIN orders o ON o.id = oi.order_id
        WHERE mi.restaurant_id = p_restaurant
          AND mi.group_id = p_group
        GROUP BY p.name
        ORDER BY revenue DESC;

    rec_restaurant cur_restaurants%ROWTYPE;
    rec_category cur_categories%ROWTYPE;
    rec_item cur_items%ROWTYPE;

    v_exists NUMBER;

BEGIN

    IF p_restaurant_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,
                                'Restaurant ID parameter is required.');
    END IF;

    SELECT COUNT(*)
    INTO v_exists
    FROM restaurant
    WHERE id = p_restaurant_id;

    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
                                'Restaurant ID does not exist.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('RESTAURANT MENU REVENUE REPORT', v_line_width/2 + 15));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('‎');

    OPEN cur_restaurants;
    LOOP
        FETCH cur_restaurants INTO rec_restaurant;
        EXIT WHEN cur_restaurants%NOTFOUND;

        v_restaurant_total := 0;
        v_top_item_revenue := 0;
        v_top_item_name := NULL;

        DBMS_OUTPUT.PUT_LINE('Restaurant: ' || rec_restaurant.name || ' (' || rec_restaurant.code || ')');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
        DBMS_OUTPUT.PUT_LINE('‎');

        OPEN cur_categories(rec_restaurant.id);
        LOOP
            FETCH cur_categories INTO rec_category;
            EXIT WHEN cur_categories%NOTFOUND;

            v_category_total := 0;

            DBMS_OUTPUT.PUT_LINE('Category: ' || rec_category.name);
            DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

            -- Header for menu items
            DBMS_OUTPUT.PUT_LINE(
                    RPAD('MENU ITEM',40) ||
                    RPAD('QUANTITY SOLD',25) ||
                    RPAD('REVENUE (RM)',20)
            );
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

            OPEN cur_items(rec_restaurant.id, rec_category.id);
            LOOP
                FETCH cur_items INTO rec_item;
                EXIT WHEN cur_items%NOTFOUND;

                DBMS_OUTPUT.PUT_LINE(
                        RPAD(rec_item.product_name,40) ||
                        LPAD(rec_item.quantity_sold,13) ||
                        LPAD(TO_CHAR(rec_item.revenue,'999,999.99'),23)
                );

                v_category_total := v_category_total + rec_item.revenue;
                v_restaurant_total := v_restaurant_total + rec_item.revenue;

                IF rec_item.revenue > v_top_item_revenue THEN
                    v_top_item_revenue := rec_item.revenue;
                    v_top_item_name := rec_item.product_name;
                END IF;

            END LOOP;
            CLOSE cur_items;

            DBMS_OUTPUT.PUT_LINE(RPAD('-',80,'-'));
            DBMS_OUTPUT.PUT_LINE('Category Total Revenue: RM ' || TO_CHAR(v_category_total,'999,999.99'));
            DBMS_OUTPUT.PUT_LINE('‎');

        END LOOP;
        CLOSE cur_categories;

        DBMS_OUTPUT.PUT_LINE(RPAD('-',80,'-'));
        DBMS_OUTPUT.PUT_LINE('Restaurant Total Revenue: RM ' || TO_CHAR(v_restaurant_total,'999,999.99'));

        IF v_top_item_name IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Top Revenue Item: ' || v_top_item_name ||
                                 ' (RM ' || TO_CHAR(v_top_item_revenue,'999,999.99') || ')');
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));

    END LOOP;
    CLOSE cur_restaurants;

    DBMS_OUTPUT.PUT_LINE('END OF REPORT');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));

END;
/

commit;

-- EXEC proc_menu_revenue_report;        //invalid: no input
-- EXEC proc_menu_revenue_report(x);     //invalid: wrong input
-- EXEC proc_menu_detailed_report(1);    //display restaurant revenue

-- Report - 2
-- Display a restaurant feedback by menu item group
CREATE OR REPLACE PROCEDURE proc_feedback_menu_item_by_restaurant (
    p_restaurant_id IN NUMBER
) IS
    v_line_width CONSTANT NUMBER := 120;
    v_restaurant_exists NUMBER;
    v_restaurant_name VARCHAR2(200);

    v_max_feedback NUMBER := 0;
    v_max_rating NUMBER := 0;

    v_most_feedback_items VARCHAR2(1000) := '';
    v_highest_rating_items VARCHAR2(1000) := '';

    CURSOR cur_groups IS
        SELECT DISTINCT mig.id, mig.name
        FROM menu_item mi
                 JOIN menu_item_group mig ON mi.group_id = mig.id
        WHERE mi.restaurant_id = p_restaurant_id
        ORDER BY mig.name;

    rec_group cur_groups%ROWTYPE;

    CURSOR cur_items(p_group_id NUMBER) IS
        SELECT p.name AS item_name,
               ROUND(AVG(f.rating),2) AS avg_rating,
               COUNT(f.id) AS feedback_count
        FROM menu_item mi
                 JOIN product p ON mi.product_id = p.id
                 LEFT JOIN order_item oi ON oi.product_id = mi.product_id
                 LEFT JOIN orders o ON oi.order_id = o.id
                 LEFT JOIN feedback f ON f.order_item_id = oi.id
        WHERE mi.restaurant_id = p_restaurant_id
          AND mi.group_id = p_group_id
        GROUP BY p.name
        ORDER BY p.name;

    rec_item cur_items%ROWTYPE;

BEGIN
    IF p_restaurant_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Restaurant ID parameter is required.');
    END IF;

    IF p_restaurant_id IS NOT NULL THEN 
        SELECT COUNT(*) INTO v_restaurant_exists 
        FROM restaurant 
        WHERE id = p_restaurant_id;
        
        IF v_restaurant_exists = 0 THEN 
            RAISE_APPLICATION_ERROR(-20001, 'Restaurant not found for ID ' || p_restaurant_id); 
        END IF; 
        
    END IF;

    SELECT name INTO v_restaurant_name
    FROM restaurant
    WHERE id = p_restaurant_id;

    -- Header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('FEEDBACK SUMMARY BY MENU ITEM GROUP', v_line_width/2 + 17, '‎'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('Restaurant: ' || v_restaurant_name);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

    DBMS_OUTPUT.PUT_LINE(
            RPAD('GROUP NAME',30) ||
            RPAD('MENU ITEM',40) ||
            RPAD('AVG RATING',15) ||
            RPAD('FEEDBACK COUNT',15)
    );

    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

    OPEN cur_groups;
    LOOP
        FETCH cur_groups INTO rec_group;
        EXIT WHEN cur_groups%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(RPAD(rec_group.name,30) || RPAD('',90));

        OPEN cur_items(rec_group.id);
        LOOP
            FETCH cur_items INTO rec_item;
            EXIT WHEN cur_items%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                    RPAD('‎',30) ||
                    RPAD(rec_item.item_name,40) ||
                    RPAD(rec_item.avg_rating,15) ||
                    RPAD(rec_item.feedback_count,15)
            );

            IF rec_item.feedback_count > v_max_feedback THEN
                v_max_feedback := rec_item.feedback_count;
                v_most_feedback_items := rec_item.item_name || '(' || rec_item.feedback_count || ')';
            ELSIF rec_item.feedback_count = v_max_feedback THEN
                v_most_feedback_items := v_most_feedback_items || ', ' ||
                                         rec_item.item_name || '(' || rec_item.feedback_count || ')';
            END IF;

            IF rec_item.avg_rating > v_max_rating THEN
                v_max_rating := rec_item.avg_rating;
                v_highest_rating_items := rec_item.item_name || '(' || rec_item.avg_rating || ')';
            ELSIF rec_item.avg_rating = v_max_rating THEN
                v_highest_rating_items := v_highest_rating_items || ', ' ||
                                          rec_item.item_name || '(' || rec_item.avg_rating || ')';
            END IF;

        END LOOP;
        CLOSE cur_items;

        DBMS_OUTPUT.PUT_LINE('‎'); 
    END LOOP;
    CLOSE cur_groups;
    
    -- Footer
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
    DBMS_OUTPUT.PUT_LINE('Most Feedback Item : ' || (v_most_feedback_items));
    DBMS_OUTPUT.PUT_LINE('Highest Rated Item : ' || (v_highest_rating_items));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('END OF REPORT', v_line_width/2 + 6, '‎'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));

END;
/

-- EXEC proc_feedback_menu_item_by_restaurant(5);   //display specific restaurant
-- EXEC proc_feedback_menu_item_by_restaurant(0);   //display invalid restaurant

commit;
-- =========================
-- Extra: index - 1
-- Create index from menu item to restaurant
CREATE INDEX idx_menu_item_restaurant_id ON menu_item(restaurant_id);

-- Extra: index - 2
-- Create index from feedback to order_item
CREATE INDEX idx_feedback_order_item ON feedback(order_item_id);

