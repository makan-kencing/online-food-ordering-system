-- ========================================
-- VIEW 1: PRODUCT FEATURE HIERARCHY VIEW
-- Shows complete product hierarchy with feature groups and features
-- ========================================
CREATE OR REPLACE VIEW vw_product_feature_hierarchy AS
WITH grouped_features AS (
    SELECT
        p.id AS product_id,
        p.code AS product_code,
        p.name AS product_name,
        p.description AS product_description,
        fg.id AS feature_group_id,
        fg.name AS feature_group_name,
        fg.min AS min_required,
        fg.max AS max_allowed,
        LISTAGG(pf.name, ', ') WITHIN GROUP (ORDER BY pf.name) AS features_in_group
    FROM product p
             JOIN product_attribute pa ON p.id = pa.product_id
             JOIN product_feature_group fg ON pa.product_feature_group_id = fg.id
             JOIN product_feature_group_field fgf ON fg.id = fgf.product_feature_group_id
             JOIN product_feature pf ON fgf.product_feature_id = pf.id
    GROUP BY p.id, p.code, p.name, p.description, fg.id, fg.name, fg.min, fg.max
)
SELECT
    product_id,
    product_code,
    product_name,
    product_description,
    feature_group_name,
    min_required,
    max_allowed,
    features_in_group
FROM grouped_features
ORDER BY product_id, feature_group_name;

SELECT * FROM vw_product_feature_hierarchy WHERE product_code = 'R1PIZ001';
SELECT * FROM vw_product_feature_hierarchy WHERE product_code = 'R1PIZ004';
SELECT * FROM vw_product_feature_hierarchy;


-- ========================================
-- VIEW 2: PRODUCT CATEGORY HIERARCHY
-- Shows complete product hierarchy with product categories and subcategories
-- ========================================
CREATE OR REPLACE VIEW vw_product_category_hierarchy AS
SELECT
    pc.id AS category_id,
    pc.name AS category_name,
    parent.name AS parent_category,
    pcc.is_primary,
    p.id AS product_id,
    p.code AS product_code,
    p.name AS product_name
FROM product_category pc
         LEFT JOIN product_category parent ON pc.parent = parent.id
         LEFT JOIN product_category_classification pcc ON pc.id = pcc.product_category_id
         LEFT JOIN product p ON pcc.product_id = p.id
WHERE (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP)
ORDER BY pc.name, p.name;

SELECT * FROM vw_product_category_hierarchy WHERE is_primary = false;
SELECT * FROM vw_product_category_hierarchy;


-- ========================================
-- PROCEDURE 1: ADD SINGLE FEATURE TO EXISTING FEATURE GROUP
-- Creates NEW feature and attaches to EXISTING feature group
-- ========================================
CREATE OR REPLACE PROCEDURE add_feature_to_group(
    p_product_code IN VARCHAR2,
    p_feature_name IN VARCHAR2,
    p_feature_code IN VARCHAR2 DEFAULT NULL,
    p_group_name IN VARCHAR2 DEFAULT 'General'
) IS
    v_product_id INT;
    v_feature_id INT;
    v_group_id INT;
    v_auto_feature_code VARCHAR2(200);
    v_restaurant_owner_id INT;
BEGIN
    SELECT id, created_by_id INTO v_product_id, v_restaurant_owner_id
    FROM product WHERE code = p_product_code;

    v_auto_feature_code := NVL(p_feature_code, UPPER(p_product_code || '_' || REPLACE(p_feature_name, ' ', '_')));

    INSERT INTO product_feature (name, code, created_by_id)
    VALUES (p_feature_name, v_auto_feature_code, v_restaurant_owner_id)
    RETURNING id INTO v_feature_id;

    SELECT fg.id INTO v_group_id
    FROM product_feature_group fg
             JOIN product_attribute pa ON fg.id = pa.product_feature_group_id
    WHERE pa.product_id = v_product_id
      AND fg.name = p_group_name || '_' || p_product_code
      AND fg.created_by_id = v_restaurant_owner_id;

    INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
    VALUES (v_group_id, v_feature_id);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Feature "' || p_feature_name || '" added to product ' || p_product_code);
    DBMS_OUTPUT.PUT_LINE('  Created new feature: ' || v_auto_feature_code);
    DBMS_OUTPUT.PUT_LINE('  Added to existing group: ' || p_group_name || '_' || p_product_code);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Error: Feature group "' || p_group_name || '" not found for product ' || p_product_code);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Error: ' || SQLERRM);
END;
/

-- ========================================
-- PROCEDURE 2: ADD FEATURE GROUP TO EXISTING PRODUCT
-- Creates NEW feature group with NEW features
-- ========================================
CREATE OR REPLACE PROCEDURE add_feature_group_to_product(
    p_product_code IN VARCHAR2,
    p_group_name IN VARCHAR2,
    p_feature_list IN VARCHAR2
) IS
    v_product_id INT;
    v_group_id INT;
    v_feature_name VARCHAR2(100);
    v_pos NUMBER;
    v_remainder VARCHAR2(1000);
    v_restaurant_owner_id INT;
BEGIN
    SELECT id, created_by_id INTO v_product_id, v_restaurant_owner_id
    FROM product WHERE code = p_product_code;

    INSERT INTO product_feature_group (name, min, max, created_by_id)
    VALUES (p_group_name || '_' || p_product_code, 1, 1, v_restaurant_owner_id)
    RETURNING id INTO v_group_id;

    INSERT INTO product_attribute (product_id, product_feature_group_id)
    VALUES (v_product_id, v_group_id);

    v_remainder := p_feature_list;
    LOOP
        v_pos := INSTR(v_remainder, ',');
        IF v_pos = 0 THEN
            v_feature_name := TRIM(v_remainder);
            IF v_feature_name IS NOT NULL THEN
                add_feature_to_group(p_product_code, v_feature_name, NULL, p_group_name);
            END IF;
            EXIT;
        ELSE
            v_feature_name := TRIM(SUBSTR(v_remainder, 1, v_pos - 1));
            add_feature_to_group(p_product_code, v_feature_name, NULL, p_group_name);
            v_remainder := SUBSTR(v_remainder, v_pos + 1);
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('✓ Feature group "' || p_group_name || '" added to product ' || p_product_code);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ========================================
-- PROCEDURE 3: CREATE NEW PRODUCT WITH FEATURE GROUPS
-- Creates a new product and sets up its feature groups
-- ========================================
CREATE OR REPLACE PROCEDURE setup_product(
    p_product_code IN VARCHAR2,
    p_product_name IN VARCHAR2,
    p_product_description IN VARCHAR2,
    p_features_config IN VARCHAR2,
    p_owner_member_id IN NUMBER 
) IS
    v_product_id INT;
    v_group_name VARCHAR2(100);
    v_feature_list VARCHAR2(1000);
    v_pos NUMBER;
    v_pipe_pos NUMBER;
    v_config_remainder VARCHAR2(2000);
BEGIN
    INSERT INTO product (code, name, description, introduction_date, created_by_id)
    VALUES (p_product_code, p_product_name, p_product_description, CURRENT_TIMESTAMP, p_owner_member_id)
    RETURNING id INTO v_product_id;

    v_config_remainder := p_features_config;
    LOOP
        v_pipe_pos := INSTR(v_config_remainder, '|');
        IF v_pipe_pos = 0 THEN
            v_pos := INSTR(v_config_remainder, ':');
            IF v_pos > 0 THEN
                v_group_name := TRIM(SUBSTR(v_config_remainder, 1, v_pos - 1));
                v_feature_list := TRIM(SUBSTR(v_config_remainder, v_pos + 1));
                add_feature_group_to_product(p_product_code, v_group_name, v_feature_list);
            END IF;
            EXIT;
        ELSE
            v_pos := INSTR(SUBSTR(v_config_remainder, 1, v_pipe_pos), ':');
            IF v_pos > 0 THEN
                v_group_name := TRIM(SUBSTR(v_config_remainder, 1, v_pos - 1));
                v_feature_list := TRIM(SUBSTR(v_config_remainder, v_pos + 1, v_pipe_pos - v_pos - 1));
                add_feature_group_to_product(p_product_code, v_group_name, v_feature_list);
            END IF;
            v_config_remainder := SUBSTR(v_config_remainder, v_pipe_pos + 1);
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('✓ Product "' || p_product_code || '" created successfully!');
    DBMS_OUTPUT.PUT_LINE('  Name: ' || p_product_name);
    DBMS_OUTPUT.PUT_LINE('  Owner Member ID: ' || p_owner_member_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ======================================================
-- TRIGGER 1: PREVENT PRODUCT DELETE IF FEATURES ASSIGNED
-- ======================================================
CREATE OR REPLACE TRIGGER trg_prevent_product_delete
    BEFORE DELETE ON product
    FOR EACH ROW
DECLARE
    v_attribute_count INT;
    v_classification_count INT;

    e_product_has_features EXCEPTION;
    e_product_has_categories EXCEPTION;

    v_error_code NUMBER;
    v_error_message VARCHAR2(500);

BEGIN
    SELECT COUNT(*) INTO v_attribute_count
    FROM product_attribute
    WHERE product_id = :OLD.id;

    SELECT COUNT(*) INTO v_classification_count
    FROM product_category_classification
    WHERE product_id = :OLD.id;

    IF v_attribute_count > 0 AND v_classification_count > 0 THEN
        v_error_code := -20023;
        v_error_message := 'Cannot delete product: It has ' || v_attribute_count ||
                           ' feature group(s) AND ' || v_classification_count ||
                           ' category classification(s) assigned.';
        RAISE e_product_has_features;
    ELSIF v_attribute_count > 0 THEN
        v_error_code := -20021;
        v_error_message := 'Cannot delete product: It has ' || v_attribute_count ||
                           ' feature group(s) assigned.';
        RAISE e_product_has_features;
    ELSIF v_classification_count > 0 THEN
        v_error_code := -20022;
        v_error_message := 'Cannot delete product: It has ' || v_classification_count ||
                           ' category classification(s) assigned.';
        RAISE e_product_has_categories;
    END IF;

EXCEPTION
    WHEN e_product_has_features THEN
        RAISE_APPLICATION_ERROR(v_error_code, v_error_message);
    WHEN e_product_has_categories THEN
        RAISE_APPLICATION_ERROR(v_error_code, v_error_message);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in trg_prevent_product_delete: ' || SQLERRM);
END;
/

-- =============================================
-- REPORT 1: FEATURE POPULARITY & USAGE REPORT
-- Shows actual customer feature selections from orders
-- =============================================
CREATE OR REPLACE PROCEDURE feature_popularity_report (
    p_restaurant_code IN VARCHAR2 DEFAULT NULL,
    p_member_id IN NUMBER DEFAULT NULL
) IS
    v_line_width CONSTANT NUMBER := 120;
    v_total_products NUMBER := 0;
    v_total_orders NUMBER := 0;
    v_orders_with_features NUMBER := 0;
    v_orders_without_features NUMBER := 0;
    v_total_revenue NUMBER := 0;
    v_total_product_revenue NUMBER := 0;
    v_total_feature_revenue NUMBER := 0;
    v_total_feature_selections NUMBER := 0;
    v_filter_member_id NUMBER;
    v_restaurant_id NUMBER;
    v_restaurant_name VARCHAR2(100);
    v_restaurant_code VARCHAR2(10);
    v_member_name VARCHAR2(100);
    v_filter_text VARCHAR2(200);
    v_group_count NUMBER := 0;
    v_center_padding NUMBER;

    -- Get restaurant info
    CURSOR cur_restaurant_info IS
        SELECT r.id, r.name, r.code, r.created_by_id, m.username
        FROM restaurant r
                 JOIN member m ON r.created_by_id = m.id
        WHERE (p_restaurant_code IS NOT NULL AND r.code = p_restaurant_code)
           OR (p_member_id IS NOT NULL AND r.created_by_id = p_member_id);

    -- Feature groups 
    CURSOR cur_feature_groups IS
        SELECT
            REPLACE(fg.name, '_' || prod.code, '') AS group_name,
            COUNT(DISTINCT pa.product_id) AS products_with_group,
            COUNT(DISTINCT oif.order_item_id) AS times_selected,
            ROUND(COUNT(DISTINCT oif.order_item_id) * 100 / NULLIF(v_total_feature_selections, 0), 1) AS popularity_pct,
            SUM(oif.quantity) AS total_quantity_selected,
            SUM(oif.quantity * oif.unit_price) AS total_revenue_from_group
        FROM product_feature_group fg
                 JOIN product_attribute pa ON fg.id = pa.product_feature_group_id
                 JOIN product prod ON pa.product_id = prod.id
                 JOIN product_feature_group_field fgf ON fg.id = fgf.product_feature_group_id
                 JOIN order_item_feature oif ON fgf.product_feature_id = oif.product_feature_id
                 JOIN order_item oi ON oif.order_item_id = oi.id
                 JOIN orders o ON oi.order_id = o.id
        WHERE prod.created_by_id = v_filter_member_id
          AND fg.created_by_id = v_filter_member_id
          AND o.restaurant_id = v_restaurant_id
          AND oi.product_id IN (
            SELECT p.id
            FROM product p
            WHERE p.created_by_id = v_filter_member_id
        )
        GROUP BY REPLACE(fg.name, '_' || prod.code, '')
        HAVING COUNT(DISTINCT oif.order_item_id) > 0
        ORDER BY times_selected DESC, group_name;

    -- Features that belong to feature groups
    CURSOR cur_features_in_group (p_group_name VARCHAR2) IS
        SELECT
            pf.name AS feature_name,
            COUNT(DISTINCT oif.order_item_id) AS times_selected,
            SUM(oif.quantity) AS total_quantity,
            SUM(oif.quantity * oif.unit_price) AS revenue,
            ROUND(COUNT(DISTINCT oif.order_item_id) * 100 / NULLIF(v_total_feature_selections, 0), 1) AS selection_pct
        FROM product_feature pf
                 JOIN product_feature_group_field fgf ON pf.id = fgf.product_feature_id
                 JOIN product_feature_group fg ON fgf.product_feature_group_id = fg.id
                 JOIN order_item_feature oif ON pf.id = oif.product_feature_id
                 JOIN order_item oi ON oif.order_item_id = oi.id
                 JOIN orders o ON oi.order_id = o.id
                 JOIN product prod ON oi.product_id = prod.id
        WHERE REPLACE(fg.name, '_' || prod.code, '') = p_group_name
          AND pf.created_by_id = v_filter_member_id
          AND o.restaurant_id = v_restaurant_id
          AND oi.product_id IN (
            SELECT p.id
            FROM product p
            WHERE p.created_by_id = v_filter_member_id
        )
        GROUP BY pf.name
        ORDER BY times_selected DESC, feature_name;

    v_group_rec cur_feature_groups%ROWTYPE;
    v_feature_rec cur_features_in_group%ROWTYPE;
    v_info_rec cur_restaurant_info%ROWTYPE;

BEGIN
    OPEN cur_restaurant_info;
    FETCH cur_restaurant_info INTO v_info_rec;
    IF cur_restaurant_info%FOUND THEN
        v_filter_member_id := v_info_rec.created_by_id;
        v_restaurant_id := v_info_rec.id;
        v_restaurant_name := v_info_rec.name;
        v_restaurant_code := v_info_rec.code;
        v_member_name := v_info_rec.username;
        v_filter_text := 'RESTAURANT: ' || v_restaurant_code || ' - ' || v_restaurant_name || ' (Managed by: ' || v_member_name || ')';
    ELSE
        v_filter_member_id := NULL;
        DBMS_OUTPUT.PUT_LINE('ERROR: No restaurant found for the given filter.');
        RETURN;
    END IF;
    CLOSE cur_restaurant_info;

    SELECT COUNT(DISTINCT o.id) INTO v_total_orders
    FROM orders o
    WHERE o.restaurant_id = v_restaurant_id;

    SELECT COUNT(DISTINCT o.id) INTO v_orders_with_features
    FROM orders o
    WHERE o.restaurant_id = v_restaurant_id
      AND EXISTS (
        SELECT 1
        FROM order_item oi
                 JOIN order_item_feature oif ON oi.id = oif.order_item_id
        WHERE oi.order_id = o.id
          AND oi.product_id IN (
            SELECT p.id
            FROM product p
            WHERE p.created_by_id = v_filter_member_id
        )
    );

    v_orders_without_features := v_total_orders - v_orders_with_features;

    SELECT NVL(SUM(oi.quantity * oi.unit_price), 0) INTO v_total_product_revenue
    FROM order_item oi
             JOIN orders o ON oi.order_id = o.id
    WHERE o.restaurant_id = v_restaurant_id
      AND oi.product_id IN (
        SELECT p.id
        FROM product p
        WHERE p.created_by_id = v_filter_member_id
    );

    SELECT NVL(SUM(oif.quantity * oif.unit_price), 0) INTO v_total_feature_revenue
    FROM order_item_feature oif
             JOIN order_item oi ON oif.order_item_id = oi.id
             JOIN orders o ON oi.order_id = o.id
    WHERE o.restaurant_id = v_restaurant_id
      AND oi.product_id IN (
        SELECT p.id
        FROM product p
        WHERE p.created_by_id = v_filter_member_id
    );

    v_total_revenue := v_total_product_revenue + v_total_feature_revenue;

    SELECT COUNT(DISTINCT oif.order_item_id) INTO v_total_feature_selections
    FROM order_item_feature oif
             JOIN order_item oi ON oif.order_item_id = oi.id
             JOIN orders o ON oi.order_id = o.id
    WHERE o.restaurant_id = v_restaurant_id
      AND oi.product_id IN (
        SELECT p.id
        FROM product p
        WHERE p.created_by_id = v_filter_member_id
    );

    SELECT COUNT(*) INTO v_total_products
    FROM product
    WHERE created_by_id = v_filter_member_id;

    -- Header
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('FEATURE POPULARITY & USAGE REPORT')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'FEATURE POPULARITY & USAGE REPORT');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', (v_line_width - LENGTH(v_filter_text)) / 2) || v_filter_text);
    DBMS_OUTPUT.PUT_LINE('');

    -- Overall Statistics
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('OVERALL STATISTICS')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'OVERALL STATISTICS');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Total Orders:                       ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE('    Orders WITH Feature Add-ons:      ' || v_orders_with_features || ' (' || ROUND(v_orders_with_features * 100 / NULLIF(v_total_orders, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('    Orders WITHOUT Feature Add-ons:   ' || v_orders_without_features || ' (' || ROUND(v_orders_without_features * 100 / NULLIF(v_total_orders, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Total Product Revenue:              RM ' || TO_CHAR(v_total_product_revenue, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('  Total Feature Add-on Revenue:       RM ' || TO_CHAR(v_total_feature_revenue, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('  TOTAL REVENUE (Product + Features): RM ' || TO_CHAR(v_total_revenue, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('  Total Products:                     ' || v_total_products);
    DBMS_OUTPUT.PUT_LINE('  Total Feature Selections:           ' || v_total_feature_selections);
    DBMS_OUTPUT.PUT_LINE('  Avg Features Per Order (with features): ' || ROUND(v_total_feature_selections / NULLIF(v_orders_with_features, 0), 1));
    DBMS_OUTPUT.PUT_LINE('');

    -- Feature Groups with customer selection data
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('FEATURE GROUP CUSTOMER PREFERENCE')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'FEATURE GROUP CUSTOMER PREFERENCE');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    OPEN cur_feature_groups;
    LOOP
        FETCH cur_feature_groups INTO v_group_rec;
        EXIT WHEN cur_feature_groups%NOTFOUND;

        v_group_count := v_group_count + 1;

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(v_group_count || '. ' || v_group_rec.group_name);
        DBMS_OUTPUT.PUT_LINE('   Times Selected:    ' || v_group_rec.times_selected ||
                             ' (' || v_group_rec.popularity_pct || '% of all selections)');
        DBMS_OUTPUT.PUT_LINE('   Quantity Selected: ' || v_group_rec.total_quantity_selected);
        DBMS_OUTPUT.PUT_LINE('   Add-on Revenue:    RM ' || TO_CHAR(v_group_rec.total_revenue_from_group, '999,990.00'));
        DBMS_OUTPUT.PUT_LINE(RPAD('   ' || RPAD('-', 90, '-'), v_line_width, '-'));
        DBMS_OUTPUT.PUT_LINE(RPAD('     FEATURE NAME', 35) ||
                             RPAD('TIMES', 12) ||
                             RPAD('QUANTITY', 12) ||
                             'ADD-ON REVENUE');
        DBMS_OUTPUT.PUT_LINE(RPAD('     ' || RPAD('-', 90, '-'), v_line_width, '-'));

        OPEN cur_features_in_group(v_group_rec.group_name);
        LOOP
            FETCH cur_features_in_group INTO v_feature_rec;
            EXIT WHEN cur_features_in_group%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                    RPAD('     ' || v_feature_rec.feature_name, 37) ||
                    RPAD(v_feature_rec.times_selected, 12) ||
                    RPAD(v_feature_rec.total_quantity, 12) ||
                    'RM ' || TO_CHAR(v_feature_rec.revenue, '999,990.00')
            );
        END LOOP;
        CLOSE cur_features_in_group;
    END LOOP;
    CLOSE cur_feature_groups;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total Feature Groups with Selections: ' || v_group_count);
    DBMS_OUTPUT.PUT_LINE('');

    -- Top 5 Most Popular Features
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('TOP 5 MOST POPULAR FEATURES')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'TOP 5 MOST POPULAR FEATURES');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('  FEATURE NAME', 35) ||
                         RPAD('TIMES SELECTED', 18) ||
                         RPAD('QUANTITY', 12) ||
                         'ADD-ON REVENUE');
    DBMS_OUTPUT.PUT_LINE(RPAD('  ' || RPAD('-', 90, '-'), v_line_width, '-'));

    FOR top_feat IN (
        SELECT
            pf.name,
            COUNT(DISTINCT oif.order_item_id) AS times_selected,
            SUM(oif.quantity) AS total_quantity,
            SUM(oif.quantity * oif.unit_price) AS revenue
        FROM product_feature pf
                 JOIN order_item_feature oif ON pf.id = oif.product_feature_id
                 JOIN order_item oi ON oif.order_item_id = oi.id
                 JOIN orders o ON oi.order_id = o.id
        WHERE pf.created_by_id = v_filter_member_id
          AND o.restaurant_id = v_restaurant_id
          AND oi.product_id IN (
            SELECT p.id
            FROM product p
            WHERE p.created_by_id = v_filter_member_id
        )
        GROUP BY pf.name
        ORDER BY times_selected DESC
            FETCH FIRST 5 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                    RPAD('  ' || top_feat.name, 37) ||
                    RPAD(top_feat.times_selected, 18) ||
                    RPAD(top_feat.total_quantity, 12) ||
                    'RM ' || TO_CHAR(top_feat.revenue, '999,990.00')
            );
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    -- Footer
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('*** END OF FEATURE POPULARITY & USAGE REPORT ***')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || '*** END OF FEATURE POPULARITY & USAGE REPORT ***');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
END;
/

-- ========================================
-- REPORT 2: CATEGORY REVENUE ANALYSIS REPORT
-- Shows category and sub-category revenue
-- ========================================
CREATE OR REPLACE PROCEDURE category_revenue_report (
    p_restaurant_code IN VARCHAR2 DEFAULT NULL,
    p_member_id IN NUMBER DEFAULT NULL
) IS
    v_line_width CONSTANT NUMBER := 130;
    v_total_revenue NUMBER := 0;
    v_total_orders NUMBER := 0;
    v_restaurant_id NUMBER;
    v_restaurant_name VARCHAR2(100);
    v_restaurant_code VARCHAR2(10);
    v_member_name VARCHAR2(100);
    v_filter_text VARCHAR2(200);
    v_category_count NUMBER := 0;

    CURSOR cur_restaurant_info IS
        SELECT r.id, r.name, r.code, m.username
        FROM restaurant r
                 JOIN member m ON r.created_by_id = m.id
        WHERE (p_restaurant_code IS NOT NULL AND r.code = p_restaurant_code)
           OR (p_member_id IS NOT NULL AND r.created_by_id = p_member_id);

    -- Categories within the restaurant
    CURSOR cur_categories_with_revenue IS
        WITH order_item_total AS (
            SELECT
                oi.id AS order_item_id,
                oi.product_id,
                oi.order_id,
                oi.quantity,
                (oi.quantity * oi.unit_price) + NVL(oif.feature_total, 0) AS total_revenue
            FROM order_item oi
                     LEFT JOIN (
                SELECT order_item_id, SUM(quantity * unit_price) AS feature_total
                FROM order_item_feature
                GROUP BY order_item_id
            ) oif ON oi.id = oif.order_item_id
        ),
             product_total AS (
                 SELECT
                     p.id AS product_id,
                     p.code,
                     p.name,
                     SUM(oit.total_revenue) AS total_revenue,
                     COUNT(DISTINCT oit.order_id) AS order_count,
                     SUM(oit.quantity) AS total_quantity
                 FROM product p
                          JOIN order_item_total oit ON p.id = oit.product_id
                          JOIN orders o ON oit.order_id = o.id
                 WHERE o.restaurant_id = v_restaurant_id
                   AND p.created_by_id = (SELECT created_by_id FROM restaurant WHERE id = v_restaurant_id)
                 GROUP BY p.id, p.code, p.name
             )
        SELECT
            pc.id AS category_id,
            pc.name AS category_name,
            pc.parent,
            SUM(pt.total_revenue) AS total_revenue,
            CASE
                WHEN pc.parent IS NULL THEN (
                    SELECT COUNT(DISTINCT oit.order_id)
                    FROM order_item_total oit
                             JOIN orders o ON oit.order_id = o.id
                    WHERE o.restaurant_id = v_restaurant_id
                )
                ELSE SUM(pt.order_count) 
                END AS order_count,
            COUNT(DISTINCT pt.product_id) AS unique_products
        FROM product_category pc
                 JOIN product_category_classification pcc ON pc.id = pcc.product_category_id
                 JOIN product_total pt ON pcc.product_id = pt.product_id
        WHERE pc.created_by_id = (SELECT created_by_id FROM restaurant WHERE id = v_restaurant_id)
          AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP)
        GROUP BY pc.id, pc.name, pc.parent
        HAVING SUM(pt.total_revenue) > 0
        ORDER BY pc.parent NULLS FIRST, total_revenue DESC;

    -- Products in a specific category
    CURSOR cur_products_in_category (p_category_id INT) IS
        WITH order_item_total AS (
            SELECT
                oi.id AS order_item_id,
                oi.product_id,
                oi.order_id,
                oi.quantity,
                (oi.quantity * oi.unit_price) + NVL(oif.feature_total, 0) AS total_revenue
            FROM order_item oi
                     LEFT JOIN (
                SELECT order_item_id, SUM(quantity * unit_price) AS feature_total
                FROM order_item_feature
                GROUP BY order_item_id
            ) oif ON oi.id = oif.order_item_id
        ),
             product_total AS (
                 SELECT
                     p.id AS product_id,
                     p.code,
                     p.name,
                     SUM(oit.total_revenue) AS product_revenue,
                     COUNT(DISTINCT oit.order_id) AS times_ordered,
                     SUM(oit.quantity) AS total_quantity
                 FROM product p
                          JOIN order_item_total oit ON p.id = oit.product_id
                          JOIN orders o ON oit.order_id = o.id
                 WHERE o.restaurant_id = v_restaurant_id
                   AND p.created_by_id = (SELECT created_by_id FROM restaurant WHERE id = v_restaurant_id)
                 GROUP BY p.id, p.code, p.name
             )
        SELECT
            pt.code,
            pt.name AS product_name,
            pt.total_quantity,
            pt.times_ordered,
            pt.product_revenue
        FROM product_total pt
                 JOIN product_category_classification pcc ON pt.product_id = pcc.product_id
        WHERE pcc.product_category_id = p_category_id
          AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP)
        ORDER BY pt.product_revenue DESC;

    v_info_rec cur_restaurant_info%ROWTYPE;
    v_cat_rec cur_categories_with_revenue%ROWTYPE;
    v_prod_rec cur_products_in_category%ROWTYPE;
    v_prod_count NUMBER;
    v_parent_name VARCHAR2(100);
        
BEGIN
    -- Get restaurant info
    OPEN cur_restaurant_info;
    FETCH cur_restaurant_info INTO v_info_rec;
    IF cur_restaurant_info%FOUND THEN
        v_restaurant_id := v_info_rec.id;
        v_restaurant_name := v_info_rec.name;
        v_restaurant_code := v_info_rec.code;
        v_member_name := v_info_rec.username;
        v_filter_text := 'RESTAURANT: ' || v_restaurant_code || ' - ' || v_restaurant_name || ' (Managed by: ' || v_member_name || ')';
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: No restaurant found for the given filter.');
        RETURN;
    END IF;
    CLOSE cur_restaurant_info;

    SELECT COUNT(*) INTO v_total_orders FROM orders WHERE restaurant_id = v_restaurant_id;

    -- Header
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('CATEGORY REVENUE ANALYSIS REPORT', (v_line_width + LENGTH('CATEGORY REVENUE ANALYSIS REPORT'))/2, ' '));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(v_filter_text, (v_line_width + LENGTH(v_filter_text))/2, ' '));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('CATEGORY REVENUE BREAKDOWN', (v_line_width + LENGTH('CATEGORY REVENUE BREAKDOWN'))/2, ' '));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    v_total_revenue := 0;

    FOR v_cat_rec IN cur_categories_with_revenue LOOP
            IF v_cat_rec.parent IS NULL THEN
                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('+ ' || v_cat_rec.category_name ||
                                     ' | Revenue: RM ' || TO_CHAR(v_cat_rec.total_revenue, '999,999,990.00') ||
                                     ' | Orders: ' || v_cat_rec.order_count ||
                                     ' | Products: ' || v_cat_rec.unique_products);
                DBMS_OUTPUT.PUT_LINE(RPAD('  ' || RPAD('=', 110, '='), v_line_width, '='));
            ELSE
                v_category_count := v_category_count + 1;
                v_total_revenue := v_total_revenue + v_cat_rec.total_revenue;

                SELECT name INTO v_parent_name FROM product_category WHERE id = v_cat_rec.parent;

                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('    - ' || v_cat_rec.category_name ||
                                     ' (under ' || v_parent_name || ')' ||
                                     ' | Revenue: RM ' || TO_CHAR(v_cat_rec.total_revenue, '999,999,990.00') ||
                                     ' | Orders: ' || v_cat_rec.order_count ||
                                     ' | Products: ' || v_cat_rec.unique_products);
                DBMS_OUTPUT.PUT_LINE(RPAD('        ' || RPAD('-', 100, '-'), v_line_width, '-'));
                DBMS_OUTPUT.PUT_LINE(RPAD('          PRODUCT NAME', 45) ||
                                     RPAD('QUANTITY', 18) ||
                                     RPAD('TIMES ORDERED', 20) ||
                                     'REVENUE');
                DBMS_OUTPUT.PUT_LINE(RPAD('          ' || RPAD('-', 100, '-'), v_line_width, '-'));

                v_prod_count := 0;

                FOR v_prod_rec IN cur_products_in_category(v_cat_rec.category_id) LOOP
                        v_prod_count := v_prod_count + 1;
                        DBMS_OUTPUT.PUT_LINE(
                                RPAD('            ' || v_prod_rec.code || ' - ' || SUBSTR(v_prod_rec.product_name, 1, 35), 48) ||
                                RPAD(TO_CHAR(v_prod_rec.total_quantity), 18) ||
                                RPAD(TO_CHAR(v_prod_rec.times_ordered), 20) ||
                                'RM ' || TO_CHAR(v_prod_rec.product_revenue, '999,990.00')
                        );
                    END LOOP;

                IF v_prod_count = 0 THEN
                    DBMS_OUTPUT.PUT_LINE('            (No products sold in this category)');
                END IF;
            END IF;
        END LOOP;

    -- Summary
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('Total Leaf Categories: ' || v_category_count);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('SUMMARY', (v_line_width + LENGTH('SUMMARY'))/2, ' '));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TOTAL STATISTICS (Product + Feature Add-ons):');
    DBMS_OUTPUT.PUT_LINE('  Total Orders:   ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE('  Total Revenue:  RM ' || TO_CHAR(v_total_revenue, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('*** END OF CATEGORY REVENUE ANALYSIS REPORT ***', (v_line_width + LENGTH('*** END OF CATEGORY REVENUE ANALYSIS REPORT ***'))/2, ' '));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
END;
/

-- ========================================
-- USAGE EXAMPLES
-- ========================================
/*
-- Create BBQ Chicken Pizza for Restaurant 1 (owner member_id = 2)
EXEC setup_product('R1PIZ004', 'BBQ Chicken Pizza', 'Grilled chicken, BBQ sauce, red onions, cilantro', 'Size:Small,Medium,Large|Crust:Thin,Pan,Stuffed|Spice:Mild,Medium,Hot|Sauce:BBQ,Original,Ranch|Premium Toppings:Extra Chicken', 2);

-- Add Extra Bacon to Premium Toppings group
EXEC add_feature_to_group('R1PIZ004', 'Extra Bacon', NULL, 'Premium Toppings');

-- Add Extra Cheese to Premium Toppings group
EXEC add_feature_to_group('R1PIZ004', 'Extra Cheese', NULL, 'Premium Toppings');

-- Add Extra Jalapenos to Premium Toppings group
EXEC add_feature_to_group('R1PIZ004', 'Extra Jalapenos', NULL, 'Premium Toppings');

-- Add Cheese Type group with multiple cheese options
EXEC add_feature_group_to_product('R1PIZ004', 'Cheese Type', 'Mozzarella,Cheddar,Parmesan,Blue Cheese');

-- Add Sauce options group (if needed)
EXEC add_feature_group_to_product('R1PIZ004', 'Sauce Options', 'BBQ,Original,Ranch,Spicy Mayo');

-- Feature Popularity Report for Restaurant 1
EXEC feature_popularity_report('R1');

-- Category Revenue Report for Restaurant 1
EXEC category_revenue_report('R1');
*/

DELETE FROM product WHERE code = 'R1PIZ004';

BEGIN
--     Create new product
    setup_product(
            'R1PIZ004',
            'BBQ Chicken Pizza',
            'Grilled chicken, BBQ sauce, red onions, cilantro',
            'Size:Small,Medium,Large|Crust:Thin,Pan,Stuffed|Spice:Mild,Medium,Hot|Sauce:BBQ,Original,Ranch',
            2
    );

--     Create the Premium Toppings group with at least one feature
    add_feature_group_to_product('R1PIZ004', 'Premium Toppings', 'Extra Chicken');

--     Add more features to the existing Premium Toppings group
    add_feature_to_group('R1PIZ004', 'Extra Bacon', NULL, 'Premium Toppings');
    add_feature_to_group('R1PIZ004', 'Extra Cheese', NULL, 'Premium Toppings');
    add_feature_to_group('R1PIZ004', 'Extra Jalapenos', NULL, 'Premium Toppings');

--     Add a new feature group
    add_feature_group_to_product('R1PIZ004', 'Cheese Type', 'Mozzarella,Cheddar,Parmesan,Blue Cheese');

--     Assign to category
    INSERT INTO product_category_classification (product_id, product_category_id, from_date, is_primary)
    VALUES (
               (SELECT id FROM product WHERE code = 'R1PIZ004'),
               (SELECT id FROM product_category WHERE name = 'NonVeg Pizzas' AND created_by_id = 2),
               CURRENT_TIMESTAMP,
               TRUE
           );

    feature_popularity_report('R1');
    category_revenue_report('R1');
END;
/

-- View original data
SELECT id, code, name, description
FROM product
WHERE code = 'R1PIZ001';

-- Test product audit
UPDATE product
SET name = 'Margherita Pizza Deluxe'
WHERE code = 'R1PIZ001';

-- Test update multiple columns at once
UPDATE product
SET name = 'Margherita Pizza Original',
    description = 'Classic Italian pizza with fresh basil and extra virgin olive oil'
WHERE code = 'R1PIZ001';

-- Restore original name
UPDATE product
SET name = 'Margherita Pizza'
WHERE code = 'R1PIZ001';
