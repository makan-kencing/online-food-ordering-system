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

SELECT * FROM vw_product_feature_hierarchy WHERE product_code = 'PIZ-MRG-1';
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
-- PROCEDURE 1: ADD SINGLE FEATURE TO EXISTING PRODUCT
-- Adds a single feature to an existing product
-- ========================================
CREATE OR REPLACE PROCEDURE add_feature_to_product(
    p_product_code IN VARCHAR2,
    p_feature_name IN VARCHAR2,
    p_feature_code IN VARCHAR2 DEFAULT NULL,
    p_group_name IN VARCHAR2 DEFAULT 'General'
) IS
    v_product_id INT;
    v_feature_id INT;
    v_group_id INT;
    v_auto_feature_code VARCHAR2(200);
BEGIN
    SELECT id INTO v_product_id FROM product WHERE code = p_product_code;

    v_auto_feature_code := NVL(p_feature_code, UPPER(REPLACE(p_feature_name, ' ', '_')));

    BEGIN
        SELECT id INTO v_feature_id FROM product_feature WHERE code = v_auto_feature_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO product_feature (name, code, created_by_id)
            VALUES (p_feature_name, v_auto_feature_code, 1)
            RETURNING id INTO v_feature_id;
    END;

    INSERT INTO product_feature_group (name, min, max, created_by_id)
    VALUES (p_group_name || '_' || p_product_code, 0, NULL, 1)
    RETURNING id INTO v_group_id;

    INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
    VALUES (v_group_id, v_feature_id);

    INSERT INTO product_attribute (product_id, product_feature_group_id)
    VALUES (v_product_id, v_group_id);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Feature "' || p_feature_name || '" added to product ' || p_product_code);
    DBMS_OUTPUT.PUT_LINE('Created new group: ' || p_group_name || '_' || p_product_code);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Error: ' || SQLERRM);
END;
/

-- ========================================
-- PROCEDURE 2: ADD FEATURE GROUP TO EXISTING PRODUCT
-- Adds multiple features as a group to an existing product
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
BEGIN
    SELECT id INTO v_product_id FROM product WHERE code = p_product_code;

    BEGIN
        SELECT id INTO v_group_id FROM product_feature_group WHERE name = p_group_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES (p_group_name, 1, 1, 1)
            RETURNING id INTO v_group_id;
    END;

    v_remainder := p_feature_list;
    LOOP
        v_pos := INSTR(v_remainder, ',');
        IF v_pos = 0 THEN
            v_feature_name := TRIM(v_remainder);
            IF v_feature_name IS NOT NULL THEN
                add_feature_to_product(p_product_code, v_feature_name, NULL, p_group_name);
            END IF;
            EXIT;
        ELSE
            v_feature_name := TRIM(SUBSTR(v_remainder, 1, v_pos - 1));
            add_feature_to_product(p_product_code, v_feature_name, NULL, p_group_name);
            v_remainder := SUBSTR(v_remainder, v_pos + 1);
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Feature group "' || p_group_name || '" added to product ' || p_product_code);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ========================================
-- PROCEDURE 3: CREATE NEW PRODUCT WITH FEATURE GROUPS
-- Creates a new product and sets up its feature groups in one go
-- ========================================
CREATE OR REPLACE PROCEDURE setup_product(
    p_product_code IN VARCHAR2,
    p_product_name IN VARCHAR2,
    p_product_description IN VARCHAR2,
    p_features_config IN VARCHAR2
) IS
    v_product_id INT;
    v_group_name VARCHAR2(100);
    v_feature_list VARCHAR2(1000);
    v_pos NUMBER;
    v_pipe_pos NUMBER;
    v_config_remainder VARCHAR2(2000);
BEGIN
    INSERT INTO product (code, name, description, introduction_date, created_by_id)
    VALUES (p_product_code, p_product_name, p_product_description, CURRENT_TIMESTAMP, 1)
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
    
BEGIN
    SELECT COUNT(*) INTO v_attribute_count FROM product_attribute WHERE product_id = :OLD.id;
    SELECT COUNT(*) INTO v_classification_count FROM product_category_classification WHERE product_id = :OLD.id;

    IF v_attribute_count > 0 THEN
        RAISE my_custom_exc;        
    END IF;

    IF v_classification_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20022, 'Cannot delete product: It has ' || v_classification_count || ' category classification(s).');
    END IF;
EXCEPTION
    WHEN my_custom_exc THEN
        RAISE_APPLICATION_ERROR(-20021, 'Cannot delete product: It has ' || v_attribute_count || ' feature group(s) assigned.');
END;
/

-- =============================================
-- REPORT 1: PRODUCT FEATURE DISTRIBUTION REPORT
-- =============================================
CREATE OR REPLACE PROCEDURE feature_usage_report (
    p_page_size IN NUMBER DEFAULT 10,
    p_page_number IN NUMBER DEFAULT 1
) IS
    v_line_width CONSTANT NUMBER := 90;
    v_total_products NUMBER := 0;
    v_total_features NUMBER := 0;
    v_features_used NUMBER := 0;
    v_features_never_used NUMBER := 0;
    v_products_with_features NUMBER := 0;
    v_products_without_features NUMBER := 0;
    v_total_assignments NUMBER := 0;
    v_avg_features NUMBER := 0;
    v_total_pages NUMBER := 0;
    v_start_row NUMBER := 0;
    v_end_row NUMBER := 0;
    v_counter NUMBER := 0;

    -- Cursor 1 - All features with count
    CURSOR cur_features IS
        SELECT * FROM (
                          SELECT
                              pf.id,
                              pf.name AS feature_name,
                              COUNT(DISTINCT pa.product_id) AS usage_count,
                              ROUND(COUNT(DISTINCT pa.product_id) * 100 / NULLIF(v_total_products, 0), 1) AS penetration,
                              ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT pa.product_id) DESC, pf.name) AS rn
                          FROM product_feature pf
                                   LEFT JOIN product_feature_group_field fgf ON pf.id = fgf.product_feature_id
                                   LEFT JOIN product_attribute pa ON fgf.product_feature_group_id = pa.product_feature_group_id
                          GROUP BY pf.id, pf.name
                      )
        WHERE rn BETWEEN v_start_row AND v_end_row
        ORDER BY usage_count DESC, feature_name;

    -- Cursor 2 - Which products use this feature
    CURSOR cur_feature_products (p_feature_id NUMBER) IS
        SELECT DISTINCT p.code, p.name
        FROM product p
                 JOIN product_attribute pa ON p.id = pa.product_id
                 JOIN product_feature_group_field fgf ON pa.product_feature_group_id = fgf.product_feature_group_id
        WHERE fgf.product_feature_id = p_feature_id
        ORDER BY p.code;

    -- Cursor 3 - Which feature groups contain this feature
    CURSOR cur_feature_groups (p_feature_id NUMBER) IS
        SELECT DISTINCT
            REPLACE(fg.name, '_' || p.code, '') AS group_name,
            p.code AS product_code
        FROM product_feature_group fg
                 JOIN product_feature_group_field fgf ON fg.id = fgf.product_feature_group_id
                 JOIN product_attribute pa ON fg.id = pa.product_feature_group_id
                 JOIN product p ON pa.product_id = p.id
        WHERE fgf.product_feature_id = p_feature_id
        ORDER BY product_code, group_name;

    v_feature_rec cur_features%ROWTYPE;
    v_center_padding NUMBER;
    v_feature_display_count NUMBER := 0;
    v_product_count NUMBER := 0;

BEGIN
    SELECT COUNT(*) INTO v_total_products FROM product;
    SELECT COUNT(*) INTO v_total_features FROM product_feature;

    SELECT COUNT(DISTINCT p.id) INTO v_products_with_features
    FROM product p
    WHERE EXISTS (SELECT 1 FROM product_attribute pa WHERE pa.product_id = p.id);

    v_products_without_features := v_total_products - v_products_with_features;

    SELECT COUNT(*) INTO v_total_assignments
    FROM product_attribute pa
             JOIN product_feature_group_field fgf ON pa.product_feature_group_id = fgf.product_feature_group_id;

    SELECT COUNT(DISTINCT pf.id) INTO v_features_used
    FROM product_feature pf
    WHERE EXISTS (SELECT 1 FROM product_feature_group_field fgf
                                    JOIN product_attribute pa ON fgf.product_feature_group_id = pa.product_feature_group_id
                  WHERE fgf.product_feature_id = pf.id);

    v_features_never_used := v_total_features - v_features_used;

    IF v_products_with_features > 0 THEN
        v_avg_features := ROUND(v_total_assignments / v_products_with_features, 1);
    END IF;

    IF p_page_size > 0 THEN
        v_total_pages := CEIL(v_total_features / p_page_size);
    ELSE
        v_total_pages := 1;
    END IF;

    IF p_page_number < 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Page number must be at least 1');
    ELSIF p_page_number > v_total_pages AND v_total_pages > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Page ' || p_page_number || ' does not exist. Total pages: ' || v_total_pages);
    END IF;

    v_start_row := (p_page_number - 1) * p_page_size + 1;
    v_end_row := LEAST(p_page_number * p_page_size, v_total_features);

    -- Header
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('FEATURE DISTRIBUTION REPORT')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'FEATURE DISTRIBUTION REPORT');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('');

    v_counter := v_start_row;
    OPEN cur_features;
    LOOP
        FETCH cur_features INTO v_feature_rec;
        EXIT WHEN cur_features%NOTFOUND;

        v_feature_display_count := v_feature_display_count + 1;

        IF v_feature_rec.usage_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE(v_counter || '. ' || RPAD(v_feature_rec.feature_name, 35) ||
                                 '→ Available in 0 products (Unused)');
        ELSIF v_feature_rec.usage_count = 1 THEN
            DBMS_OUTPUT.PUT_LINE(v_counter || '. ' || RPAD(v_feature_rec.feature_name, 35) ||
                                 '→ Available in 1 product (' || v_feature_rec.penetration || '% of all products)');
        ELSE
            DBMS_OUTPUT.PUT_LINE(v_counter || '. ' || RPAD(v_feature_rec.feature_name, 35) ||
                                 '→ Available in ' || v_feature_rec.usage_count || ' products (' || v_feature_rec.penetration || '% of all products)');
        END IF;

        v_product_count := 0;
        DBMS_OUTPUT.PUT_LINE('     Products:');
        FOR v_prod_rec IN cur_feature_products(v_feature_rec.id) LOOP
                v_product_count := v_product_count + 1;
                IF v_product_count <= 5 THEN
                    DBMS_OUTPUT.PUT_LINE('       • ' || v_prod_rec.code || ' - ' || v_prod_rec.name);
                ELSIF v_product_count = 6 THEN
                    DBMS_OUTPUT.PUT_LINE('       ... and ' || (v_feature_rec.usage_count - 5) || ' more');
                END IF;
            END LOOP;

        DBMS_OUTPUT.PUT_LINE('     Feature Groups:');
        FOR v_group_rec IN cur_feature_groups(v_feature_rec.id) LOOP
                DBMS_OUTPUT.PUT_LINE('       • ' || v_group_rec.group_name || ' (for product ' || v_group_rec.product_code || ')');
            END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
        v_counter := v_counter + 1;

    END LOOP;
    CLOSE cur_features;

    -- Summary
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('SUMMARY')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'SUMMARY');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    DBMS_OUTPUT.PUT_LINE('Total Products:                     ' || v_total_products);
    DBMS_OUTPUT.PUT_LINE('Products WITH Features:             ' || v_products_with_features || ' (' || ROUND(v_products_with_features * 100 / NULLIF(v_total_products, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Products WITHOUT Features:          ' || v_products_without_features || ' (' || ROUND(v_products_without_features * 100 / NULLIF(v_total_products, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total Distinct Features:            ' || v_total_features);
    DBMS_OUTPUT.PUT_LINE('Features Currently Used:            ' || v_features_used);
    DBMS_OUTPUT.PUT_LINE('Features NEVER Used:                ' || v_features_never_used);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total Feature Assignments:          ' || v_total_assignments);
    DBMS_OUTPUT.PUT_LINE('Average Features per Product:       ' || v_avg_features);
    DBMS_OUTPUT.PUT_LINE('');

    -- Footer
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', (v_line_width - LENGTH('Page ' || p_page_number || ' of ' || v_total_pages)) / 2)
        || 'Page ' || p_page_number || ' of ' || v_total_pages);
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('*** END OF FEATURE DISTRIBUTION REPORT ***')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || '*** END OF FEATURE DISTRIBUTION REPORT ***');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
END;
/

-- ========================================
-- REPORT 2: PRODUCT CATEGORY SUMMARY REPORT
-- ========================================
CREATE OR REPLACE PROCEDURE product_category_summary_report IS
    v_line_width CONSTANT NUMBER := 110;
    v_total_products NUMBER := 0;
    v_total_categorized NUMBER := 0;
    v_products_uncategorized NUMBER := 0;
    v_total_assignments NUMBER := 0;
    v_total_categories NUMBER := 0;
    v_categories_with_products NUMBER := 0;
    v_avg_products_per_category NUMBER := 0;
    v_center_padding NUMBER;
    v_total_primary NUMBER := 0;
    v_total_secondary NUMBER := 0;

    -- Cursor 1 - Parent Category
    CURSOR cur_root_categories IS
        SELECT
            pc.id,
            pc.name AS category_name,
            (SELECT COUNT(*) FROM product_category WHERE parent = pc.id) AS subcategory_count
        FROM product_category pc
        WHERE pc.parent IS NULL
        ORDER BY pc.name;

    -- Cursor 2 - Sub-Category
    CURSOR cur_subcategories (p_parent_id INT) IS
        SELECT
            pc.id,
            pc.name AS category_name,
            (SELECT COUNT(*) FROM product_category WHERE parent = pc.id) AS subcategory_count
        FROM product_category pc
        WHERE pc.parent = p_parent_id
        ORDER BY pc.name;

    -- Cursor 3 - Products in Category
    CURSOR cur_category_products (p_category_id INT) IS
        SELECT
            COUNT(DISTINCT pcc.product_id) AS product_count,
            SUM(CASE WHEN pcc.is_primary = 1 THEN 1 ELSE 0 END) AS primary_count
        FROM product_category_classification pcc
        WHERE pcc.product_category_id = p_category_id
          AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP);

    v_root_rec cur_root_categories%ROWTYPE;
    v_sub_rec cur_subcategories%ROWTYPE;
    v_prod_stats_rec cur_category_products%ROWTYPE;

    v_root_count NUMBER := 0;
    v_sub_count NUMBER := 0;
    v_root_product_count NUMBER := 0;
    v_root_primary_count NUMBER := 0;

BEGIN
    SELECT COUNT(*) INTO v_total_products FROM product;
    SELECT COUNT(*) INTO v_total_categories FROM product_category;

    SELECT COUNT(*) INTO v_products_uncategorized
    FROM product p
    WHERE NOT EXISTS (
        SELECT 1 FROM product_category_classification pcc
        WHERE pcc.product_id = p.id
          AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP)
    );

    v_total_categorized := v_total_products - v_products_uncategorized;

    SELECT COUNT(*) INTO v_total_assignments
    FROM product_category_classification pcc
    WHERE (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP);

    SELECT COUNT(*) INTO v_total_primary
    FROM product_category_classification pcc
    WHERE pcc.is_primary = 1
      AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP);

    v_total_secondary := v_total_assignments - v_total_primary;

    SELECT COUNT(*) INTO v_categories_with_products
    FROM product_category pc
    WHERE EXISTS (
        SELECT 1 FROM product_category_classification pcc
        WHERE pcc.product_category_id = pc.id
          AND (pcc.thru_date IS NULL OR pcc.thru_date > CURRENT_TIMESTAMP)
    );

    IF v_categories_with_products > 0 THEN
        v_avg_products_per_category := ROUND(v_total_assignments / v_categories_with_products, 1);
    END IF;

    -- Header
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('PRODUCT CATEGORY SUMMARY REPORT')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'PRODUCT CATEGORY SUMMARY REPORT');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('CATEGORY NAME', 30) ||
                         RPAD('PARENT CATEGORY', 25) ||
                         RPAD('TOTAL PRODUCTS', 18) ||
                         RPAD('AS PRIMARY', 15) ||
                         'SUB-CATEGORIES');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

    OPEN cur_root_categories;
    LOOP
        FETCH cur_root_categories INTO v_root_rec;
        EXIT WHEN cur_root_categories%NOTFOUND;

        v_root_count := v_root_count + 1;

        OPEN cur_category_products(v_root_rec.id);
        FETCH cur_category_products INTO v_prod_stats_rec;
        CLOSE cur_category_products;

        v_root_product_count := v_prod_stats_rec.product_count;
        v_root_primary_count := v_prod_stats_rec.primary_count;

        DBMS_OUTPUT.PUT_LINE(
                RPAD(v_root_rec.category_name, 30) ||
                RPAD('ROOT', 25) ||
                RPAD(v_root_product_count, 18) ||
                RPAD(v_root_primary_count, 15) ||
                v_root_rec.subcategory_count
        );

        OPEN cur_subcategories(v_root_rec.id);
        v_sub_count := 0;
        LOOP
            FETCH cur_subcategories INTO v_sub_rec;
            EXIT WHEN cur_subcategories%NOTFOUND;

            v_sub_count := v_sub_count + 1;

            OPEN cur_category_products(v_sub_rec.id);
            FETCH cur_category_products INTO v_prod_stats_rec;
            CLOSE cur_category_products;

            DBMS_OUTPUT.PUT_LINE(
                    RPAD('  ' || v_sub_rec.category_name, 30) ||
                    RPAD(v_root_rec.category_name, 25) ||
                    RPAD(v_prod_stats_rec.product_count, 18) ||
                    RPAD(v_prod_stats_rec.primary_count, 15) ||
                    v_sub_rec.subcategory_count
            );
        END LOOP;
        CLOSE cur_subcategories;

    END LOOP;
    CLOSE cur_root_categories;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Summary
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('SUMMARY')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || 'SUMMARY');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PRODUCT COVERAGE:');
    DBMS_OUTPUT.PUT_LINE('  Total Products:                 ' || v_total_products);
    DBMS_OUTPUT.PUT_LINE('  Products WITH Categories:       ' || v_total_categorized || ' (' || ROUND(v_total_categorized * 100 / v_total_products, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Products WITHOUT Categories:    ' || v_products_uncategorized || ' (' || ROUND(v_products_uncategorized * 100 / v_total_products, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CATEGORY STATISTICS:');
    DBMS_OUTPUT.PUT_LINE('  Total Categories:               ' || v_total_categories);
    DBMS_OUTPUT.PUT_LINE('  Root Categories:                ' || v_root_count);
    DBMS_OUTPUT.PUT_LINE('  Categories WITH Products:       ' || v_categories_with_products);
    DBMS_OUTPUT.PUT_LINE('  Categories WITHOUT Products:    ' || (v_total_categories - v_categories_with_products));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ASSIGNMENT BREAKDOWN:');
    DBMS_OUTPUT.PUT_LINE('  Total Category Assignments:     ' || v_total_assignments);
    DBMS_OUTPUT.PUT_LINE('  Primary Assignments:            ' || v_total_primary);
    DBMS_OUTPUT.PUT_LINE('  Secondary Assignments:          ' || v_total_secondary);
    DBMS_OUTPUT.PUT_LINE('  Avg Products per Category:      ' || v_avg_products_per_category);
    DBMS_OUTPUT.PUT_LINE('');

    -- Footer
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    v_center_padding := (v_line_width - LENGTH('*** END OF CATEGORY SUMMARY REPORT ***')) / 2;
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', v_center_padding) || '*** END OF CATEGORY SUMMARY REPORT ***');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
END;
/

-- ========================================
-- USAGE EXAMPLES
-- ========================================
SELECT * FROM vw_product_feature_hierarchy;
SELECT * FROM vw_product_feature_hierarchy WHERE product_code = 'PIZ-MRG-1';
SELECT * FROM vw_product_category_hierarchy;

-- EXEC setup_product(
--             'PIZ-DELUX-1',
--             'Deluxe Pizza',
--             'Our signature deluxe pizza',
--             'Size:Regular,Large,Personal|Crust:Thin,Pan,Stuffed|Spice:Mild,Medium,Hot'
--     );

-- EXEC add_feature_to_product('PIZ-MRG-1', 'Extra Cheese', 'TOP_EXCHZ', 'Toppings');

-- EXEC add_feature_group_to_product('PIZ-MRG-1', 'Premium Toppings', 'Extra Cheese,Extra Pepperoni,Extra Mushroom');

-- EXEC feature_usage_report;                    -- Default (10 items, page 1)
-- EXEC feature_usage_report(5, 1);              -- 5 items per page, page 1
-- EXEC feature_usage_report(5, 2);              -- 5 items per page, page 2
-- EXEC product_category_summary_report;         -- Category summary


BEGIN
--     setup_product(
--             'PIZ-DELUX-1',
--             'Deluxe Pizza',
--         'Our signature deluxe pizza',
--             'Size:Regular,Large,Personal|Crust:Thin,Pan,Stuffed|Spice:Mild,Medium,Hot'
--     );
--     add_feature_to_product('PIZ-MRG-1', 'Extra Cheese', 'TOP_EXCHZ', 'Toppings');
--     add_feature_group_to_product('PIZ-MRG-1', 'Premium Toppings', 'Extra Cheese,Extra Pepperoni,Extra Mushroom');
--     feature_usage_report(5, 1);
    product_category_summary_report;
END;
/

DELETE FROM product WHERE code = 'PIZ-MRG-1';

COMMIT;
