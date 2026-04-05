DELETE FROM menu_item;
DELETE FROM product_attribute;
DELETE FROM product_category_classification;
DELETE FROM product_feature_group_field;
DELETE FROM product;
DELETE FROM product_category;
DELETE FROM product_feature_group;
DELETE FROM product_feature;
DELETE FROM menu_item_group;

-- ============================================
-- 1. PRODUCT FEATURES
-- ============================================
INSERT INTO product_feature (name, code, created_by_id) VALUES
                                                            ('Regular', 'SIZE_REG', 1),
                                                            ('Large', 'SIZE_LRG', 1),
                                                            ('Personal', 'SIZE_PRS', 1),
                                                            ('Family', 'SIZE_FAM', 1),
                                                            ('Mild', 'SPICE_MID', 1),
                                                            ('Medium', 'SPICE_MED', 1),
                                                            ('Hot', 'SPICE_HOT', 1),
                                                            ('Extra Hot', 'SPICE_XHT', 1),
                                                            ('Thin Crust', 'CRUST_THN', 1),
                                                            ('Pan Crust', 'CRUST_PAN', 1),
                                                            ('Stuffed Crust', 'CRUST_STF', 1),
                                                            ('Cheese Burst', 'CRUST_CHZ', 1),
                                                            ('Small (250ml)', 'BEV_SMALL', 1),
                                                            ('Medium (500ml)', 'BEV_MED', 1),
                                                            ('Large (1L)', 'BEV_LARGE', 1),
                                                            ('Extra Cheese', 'TOP_EXCHZ', 1),
                                                            ('Extra Pepperoni', 'TOP_EXPEP', 1),
                                                            ('Extra Mushroom', 'TOP_EXMSH', 1),
                                                            ('Extra Onion', 'TOP_EXONI', 1),
                                                            ('No Onion', 'OPT_NOONI', 1),
                                                            ('No Garlic', 'OPT_NOGRL', 1),
                                                            ('Well Done', 'COOK_WEL', 1),
                                                            ('Regular Cook', 'COOK_REG', 1),
                                                            ('Light Cook', 'COOK_LIT', 1);

-- ============================================
-- 2. PRODUCT FEATURE GROUPS
-- ============================================
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Pizza Size', 1, 1, 1),
                                                                      ('Crust Type', 1, 1, 1),
                                                                      ('Spice Level', 1, 1, 1),
                                                                      ('Extra Toppings', 0, 5, 1),
                                                                      ('Remove Ingredients', 0, 3, 1),
                                                                      ('Beverage Size', 1, 1, 1),
                                                                      ('Ice Level', 1, 1, 1),
                                                                      ('Sugar Level', 1, 1, 1),
                                                                      ('Burger Size', 1, 1, 1),
                                                                      ('Patty Type', 1, 1, 1),
                                                                      ('Doneness', 1, 1, 1);

-- ============================================
-- 3. PRODUCT FEATURE GROUP FIELDS
-- ============================================
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Pizza Size'),
       (SELECT id FROM product_feature WHERE name = 'Regular') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Pizza Size'),
       (SELECT id FROM product_feature WHERE name = 'Large') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Pizza Size'),
       (SELECT id FROM product_feature WHERE name = 'Personal') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Pizza Size'),
       (SELECT id FROM product_feature WHERE name = 'Family') FROM DUAL;

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Crust Type'),
       (SELECT id FROM product_feature WHERE name = 'Thin Crust') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Crust Type'),
       (SELECT id FROM product_feature WHERE name = 'Pan Crust') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Crust Type'),
       (SELECT id FROM product_feature WHERE name = 'Stuffed Crust') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Crust Type'),
       (SELECT id FROM product_feature WHERE name = 'Cheese Burst') FROM DUAL;

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Spice Level'),
       (SELECT id FROM product_feature WHERE name = 'Mild') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Spice Level'),
       (SELECT id FROM product_feature WHERE name = 'Medium') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Spice Level'),
       (SELECT id FROM product_feature WHERE name = 'Hot') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Spice Level'),
       (SELECT id FROM product_feature WHERE name = 'Extra Hot') FROM DUAL;

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Extra Toppings'),
       (SELECT id FROM product_feature WHERE name = 'Extra Cheese') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Extra Toppings'),
       (SELECT id FROM product_feature WHERE name = 'Extra Pepperoni') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Extra Toppings'),
       (SELECT id FROM product_feature WHERE name = 'Extra Mushroom') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Extra Toppings'),
       (SELECT id FROM product_feature WHERE name = 'Extra Onion') FROM DUAL;

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Remove Ingredients'),
       (SELECT id FROM product_feature WHERE name = 'No Onion') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Remove Ingredients'),
       (SELECT id FROM product_feature WHERE name = 'No Garlic') FROM DUAL;

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT (SELECT id FROM product_feature_group WHERE name = 'Beverage Size'),
       (SELECT id FROM product_feature WHERE name = 'Small (250ml)') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Beverage Size'),
       (SELECT id FROM product_feature WHERE name = 'Medium (500ml)') FROM DUAL UNION ALL
SELECT (SELECT id FROM product_feature_group WHERE name = 'Beverage Size'),
       (SELECT id FROM product_feature WHERE name = 'Large (1L)') FROM DUAL;

-- ============================================
-- 4. PRODUCT CATEGORIES
-- ============================================
-- ============================================
-- 4. PRODUCT CATEGORIES (Fixed)
-- ============================================

-- Parent Categories
INSERT INTO product_category (name, description, parent, created_by_id) VALUES
                                                                            ('Pizzas', 'Delicious pizzas with various toppings', NULL, 1),
                                                                            ('Burgers', 'Juicy burgers with premium ingredients', NULL, 1),
                                                                            ('Beverages', 'Refreshing drinks and beverages', NULL, 1),
                                                                            ('Sides', 'Perfect side dishes', NULL, 1),
                                                                            ('Desserts', 'Sweet treats', NULL, 1);

-- Sub-Categories linked to Parent ID
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Veg Pizza', 'Vegetarian pizzas', id, 1 FROM product_category WHERE name = 'Pizzas' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'NonVeg Pizzas', 'Meat pizzas', id, 1 FROM product_category WHERE name = 'Pizzas' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Specialty', 'Chef specials', id, 1 FROM product_category WHERE name = 'Pizzas' AND parent IS NULL;

INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Chicken Burg', 'Chicken burgers', id, 1 FROM product_category WHERE name = 'Burgers' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Beef Burgers', 'Beef burgers', id, 1 FROM product_category WHERE name = 'Burgers' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Veggie Burg', 'Vegetarian burgers', id, 1 FROM product_category WHERE name = 'Burgers' AND parent IS NULL;

INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Carbonated', 'Soda drinks', id, 1 FROM product_category WHERE name = 'Beverages' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Juices', 'Fresh juices', id, 1 FROM product_category WHERE name = 'Beverages' AND parent IS NULL;
INSERT INTO product_category (name, description, parent, created_by_id)
SELECT 'Milkshakes', 'Creamy shakes', id, 1 FROM product_category WHERE name = 'Beverages' AND parent IS NULL;

-- ============================================
-- 5. PRODUCTS
-- ============================================
INSERT INTO product (code, name, description, introduction_date, image_url, created_by_id) VALUES
                                                                                               ('PIZ-MRG-1', 'Margherita Pizza', 'Classic Italian pizza', CURRENT_TIMESTAMP, '/images/pizzas/margherita.jpg', 1),
                                                                                               ('PIZ-PEP-1', 'Pepperoni Pizza', 'Loaded with pepperoni', CURRENT_TIMESTAMP, '/images/pizzas/pepperoni.jpg', 1),
                                                                                               ('PIZ-VEG-1', 'Garden Veggie Pizza', 'Fresh vegetables', CURRENT_TIMESTAMP, '/images/pizzas/veggie.jpg', 1),
                                                                                               ('PIZ-SUP-1', 'Supreme Pizza', 'Loaded supreme', CURRENT_TIMESTAMP, '/images/pizzas/supreme.jpg', 1),
                                                                                               ('BRG-CHZ-1', 'Classic Cheeseburger', 'Beef patty with cheese', CURRENT_TIMESTAMP, '/images/burgers/cheeseburger.jpg', 1),
                                                                                               ('BRG-CHK-1', 'Crispy Chicken Burger', 'Crispy chicken breast', CURRENT_TIMESTAMP, '/images/burgers/chicken.jpg', 1),
                                                                                               ('BRG-VEG-1', 'Veggie Supreme Burger', 'Plant-based patty', CURRENT_TIMESTAMP, '/images/burgers/veggie.jpg', 1),
                                                                                               ('BRG-DBL-1', 'Double Bacon Burger', 'Double beef with bacon', CURRENT_TIMESTAMP, '/images/burgers/double-bacon.jpg', 1),
                                                                                               ('BEV-COL-1', 'Cola', 'Classic cola', CURRENT_TIMESTAMP, '/images/beverages/cola.jpg', 1),
                                                                                               ('BEV-LEM-1', 'Lemonade', 'Fresh lemonade', CURRENT_TIMESTAMP, '/images/beverages/lemonade.jpg', 1),
                                                                                               ('BEV-CHC-1', 'Chocolate Milkshake', 'Rich chocolate shake', CURRENT_TIMESTAMP, '/images/beverages/choc-shake.jpg', 1),
                                                                                               ('BEV-ICE-1', 'Iced Lemon Tea', 'Refreshing iced tea', CURRENT_TIMESTAMP, '/images/beverages/iced-tea.jpg', 1),
                                                                                               ('SIDE-FRY1', 'French Fries', 'Crispy golden fries', CURRENT_TIMESTAMP, '/images/sides/fries.jpg', 1),
                                                                                               ('SIDE-ONI1', 'Onion Rings', 'Crispy onion rings', CURRENT_TIMESTAMP, '/images/sides/onion-rings.jpg', 1),
                                                                                               ('SIDE-WNG1', 'Chicken Wings', 'Spicy buffalo wings', CURRENT_TIMESTAMP, '/images/sides/wings.jpg', 1),
                                                                                               ('DESS-CAK1', 'Chocolate Lava Cake', 'Warm molten cake', CURRENT_TIMESTAMP, '/images/desserts/lava-cake.jpg', 1),
                                                                                               ('DESS-ICE1', 'Ice Cream Sundae', 'Vanilla sundae', CURRENT_TIMESTAMP, '/images/desserts/sundae.jpg', 1);

-- ============================================
-- 6. PRODUCT CATEGORY CLASSIFICATIONS
-- ============================================
INSERT INTO product_category_classification (product_id, product_category_id, from_date, thru_date, is_primary) VALUES
-- Pizza classifications
((SELECT id FROM product WHERE code = 'PIZ-MRG-1'), (SELECT id FROM product_category WHERE name = 'Pizzas'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'PIZ-MRG-1'), (SELECT id FROM product_category WHERE name = 'Veg Pizza'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'PIZ-PEP-1'), (SELECT id FROM product_category WHERE name = 'Pizzas'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'PIZ-PEP-1'), (SELECT id FROM product_category WHERE name = 'NonVeg Pizzas'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'PIZ-VEG-1'), (SELECT id FROM product_category WHERE name = 'Pizzas'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'PIZ-VEG-1'), (SELECT id FROM product_category WHERE name = 'Veg Pizza'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'PIZ-SUP-1'), (SELECT id FROM product_category WHERE name = 'Pizzas'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'PIZ-SUP-1'), (SELECT id FROM product_category WHERE name = 'NonVeg Pizzas'), CURRENT_TIMESTAMP, NULL, false),

-- Burger classifications
((SELECT id FROM product WHERE code = 'BRG-CHZ-1'), (SELECT id FROM product_category WHERE name = 'Burgers'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BRG-CHZ-1'), (SELECT id FROM product_category WHERE name = 'Beef Burgers'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BRG-CHK-1'), (SELECT id FROM product_category WHERE name = 'Burgers'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BRG-CHK-1'), (SELECT id FROM product_category WHERE name = 'Chicken Burg'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BRG-VEG-1'), (SELECT id FROM product_category WHERE name = 'Burgers'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BRG-VEG-1'), (SELECT id FROM product_category WHERE name = 'Veggie Burg'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BRG-DBL-1'), (SELECT id FROM product_category WHERE name = 'Burgers'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BRG-DBL-1'), (SELECT id FROM product_category WHERE name = 'Beef Burgers'), CURRENT_TIMESTAMP, NULL, false),

-- Beverage classifications
((SELECT id FROM product WHERE code = 'BEV-COL-1'), (SELECT id FROM product_category WHERE name = 'Beverages'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BEV-COL-1'), (SELECT id FROM product_category WHERE name = 'Carbonated'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BEV-LEM-1'), (SELECT id FROM product_category WHERE name = 'Beverages'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BEV-LEM-1'), (SELECT id FROM product_category WHERE name = 'Juices'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BEV-CHC-1'), (SELECT id FROM product_category WHERE name = 'Beverages'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'BEV-CHC-1'), (SELECT id FROM product_category WHERE name = 'Milkshakes'), CURRENT_TIMESTAMP, NULL, false),
((SELECT id FROM product WHERE code = 'BEV-ICE-1'), (SELECT id FROM product_category WHERE name = 'Beverages'), CURRENT_TIMESTAMP, NULL, true),

-- Side classifications
((SELECT id FROM product WHERE code = 'SIDE-FRY1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'SIDE-ONI1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'SIDE-WNG1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),

-- Dessert classifications 
((SELECT id FROM product WHERE code = 'DESS-CAK1'), (SELECT id FROM product_category WHERE name = 'Desserts'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'DESS-ICE1'), (SELECT id FROM product_category WHERE name = 'Desserts'), CURRENT_TIMESTAMP, NULL, true);

-- ============================================
-- 7. PRODUCT ATTRIBUTES
-- ============================================
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-PEP-1', 'PIZ-VEG-1', 'PIZ-SUP-1')
  AND fg.name IN ('Pizza Size', 'Crust Type', 'Spice Level', 'Extra Toppings', 'Remove Ingredients');

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1')
  AND fg.name IN ('Burger Size', 'Patty Type', 'Doneness', 'Extra Toppings');

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BEV-COL-1', 'BEV-LEM-1', 'BEV-ICE-1')
  AND fg.name IN ('Beverage Size', 'Ice Level', 'Sugar Level');

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'BEV-CHC-1'
  AND fg.name = 'Beverage Size';

-- ============================================
-- 8. MENU ITEM GROUPS
-- ============================================
INSERT INTO menu_item_group (name, description) VALUES
                                                    ('Pizzas', 'All pizza menu items'),
                                                    ('Burgers', 'All burger menu items'),
                                                    ('Beverages', 'All drink items'),
                                                    ('Sides', 'Side dishes'),
                                                    ('Desserts', 'Sweet treats'),
                                                    ('Special', 'Limited time offers'),
                                                    ('Combos', 'Value meals');

-- ============================================
-- 9. MENU ITEMS
-- ============================================
-- Restaurant 1 (Full menu)
-- INSERT INTO menu_item (PRODUCT_ID, RESTAURANT_ID, GROUP_ID, IS_UNAVAILABLE, FROM_DATE, THRU_DATE)
-- SELECT p.id, 1,
--        (SELECT id FROM menu_item_group WHERE name =
--                                              CASE p.code
--                                                  WHEN 'PIZ-MRG-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-PEP-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-VEG-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-SUP-1' THEN 'Pizzas'
--                                                  WHEN 'BRG-CHZ-1' THEN 'Burgers'
--                                                  WHEN 'BRG-CHK-1' THEN 'Burgers'
--                                                  WHEN 'BRG-VEG-1' THEN 'Burgers'
--                                                  WHEN 'BRG-DBL-1' THEN 'Burgers'
--                                                  WHEN 'BEV-COL-1' THEN 'Beverages'
--                                                  WHEN 'BEV-LEM-1' THEN 'Beverages'
--                                                  WHEN 'BEV-CHC-1' THEN 'Beverages'
--                                                  WHEN 'BEV-ICE-1' THEN 'Beverages'
--                                                  WHEN 'SIDE-FRY1' THEN 'Sides'
--                                                  WHEN 'SIDE-ONI1' THEN 'Sides'
--                                                  WHEN 'SIDE-WNG1' THEN 'Sides'
--                                                  WHEN 'DESS-CAK1' THEN 'Desserts'
--                                                  WHEN 'DESS-ICE1' THEN 'Desserts'
--                                                  END),
--        FALSE, CURRENT_TIMESTAMP, NULL
-- FROM product p;
-- 
-- -- Restaurant 2 (Partial menu)
-- INSERT INTO menu_item (PRODUCT_ID, RESTAURANT_ID, GROUP_ID, IS_UNAVAILABLE, FROM_DATE, THRU_DATE)
-- SELECT p.id, 2,
--        (SELECT id FROM menu_item_group WHERE name =
--                                              CASE p.code
--                                                  WHEN 'PIZ-MRG-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-PEP-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-VEG-1' THEN 'Pizzas'
--                                                  WHEN 'PIZ-SUP-1' THEN 'Pizzas'
--                                                  WHEN 'BRG-CHZ-1' THEN 'Burgers'
--                                                  WHEN 'BRG-CHK-1' THEN 'Burgers'
--                                                  WHEN 'BEV-COL-1' THEN 'Beverages'
--                                                  WHEN 'BEV-LEM-1' THEN 'Beverages'
--                                                  WHEN 'SIDE-FRY1' THEN 'Sides'
--                                                  WHEN 'DESS-CAK1' THEN 'Desserts'
--                                                  END),
--        CASE WHEN p.code IN ('PIZ-VEG-1', 'BRG-CHK-1') THEN TRUE ELSE FALSE END,
--        CURRENT_TIMESTAMP, NULL
-- FROM product p
-- WHERE p.code IN ('PIZ-MRG-1', 'PIZ-PEP-1', 'PIZ-VEG-1', 'PIZ-SUP-1',
--                  'BRG-CHZ-1', 'BRG-CHK-1', 'BEV-COL-1', 'BEV-LEM-1',
--                  'SIDE-FRY1', 'DESS-CAK1');
-- 
-- -- Restaurant 3 (Premium with limited offers)
-- INSERT INTO menu_item (PRODUCT_ID, RESTAURANT_ID, GROUP_ID, IS_UNAVAILABLE, FROM_DATE, THRU_DATE)
-- SELECT p.id, 3,
--        (SELECT id FROM menu_item_group WHERE name =
--                                              CASE p.code
--                                                  WHEN 'PIZ-SUP-1' THEN 'Special'
--                                                  WHEN 'BRG-DBL-1' THEN 'Burgers'
--                                                  WHEN 'BEV-CHC-1' THEN 'Beverages'
--                                                  WHEN 'SIDE-WNG1' THEN 'Sides'
--                                                  WHEN 'DESS-CAK1' THEN 'Desserts'
--                                                  END),
--        FALSE, CURRENT_TIMESTAMP,
--        CASE WHEN p.code = 'PIZ-SUP-1' THEN CURRENT_TIMESTAMP + INTERVAL '1' MONTH ELSE NULL END
-- FROM product p
-- WHERE p.code IN ('PIZ-SUP-1', 'BRG-DBL-1', 'BEV-CHC-1', 'SIDE-WNG1', 'DESS-CAK1');
-- 
-- -- Restaurant 4 (Budget)
-- INSERT INTO menu_item (PRODUCT_ID, RESTAURANT_ID, GROUP_ID, IS_UNAVAILABLE, FROM_DATE, THRU_DATE)
-- SELECT p.id, 4,
--        (SELECT id FROM menu_item_group WHERE name =
--                                              CASE p.code
--                                                  WHEN 'PIZ-MRG-1' THEN 'Combos'
--                                                  WHEN 'BRG-CHZ-1' THEN 'Combos'
--                                                  WHEN 'BEV-COL-1' THEN 'Beverages'
--                                                  WHEN 'SIDE-FRY1' THEN 'Sides'
--                                                  END),
--        FALSE, CURRENT_TIMESTAMP, NULL
-- FROM product p
-- WHERE p.code IN ('PIZ-MRG-1', 'BRG-CHZ-1', 'BEV-COL-1', 'SIDE-FRY1');
-- 
-- -- Restaurant 5 (Future availability)
-- INSERT INTO menu_item (PRODUCT_ID, RESTAURANT_ID, GROUP_ID, IS_UNAVAILABLE, FROM_DATE, THRU_DATE)
-- SELECT p.id, 5,
--        (SELECT id FROM menu_item_group WHERE name =
--                                              CASE p.code
--                                                  WHEN 'PIZ-VEG-1' THEN 'Pizzas'
--                                                  WHEN 'BRG-VEG-1' THEN 'Burgers'
--                                                  WHEN 'BEV-ICE-1' THEN 'Beverages'
--                                                  END),
--        TRUE, CURRENT_TIMESTAMP + INTERVAL '7' DAY, NULL
-- FROM product p
-- WHERE p.code IN ('PIZ-VEG-1', 'BRG-VEG-1', 'BEV-ICE-1');

COMMIT;

SELECT 'Total Products: ' || COUNT(*) FROM product;
SELECT 'Total Features: ' || COUNT(*) FROM product_feature;
SELECT 'Total Feature Groups: ' || COUNT(*) FROM product_feature_group;
-- SELECT 'Total Menu Items: ' || COUNT(*) FROM menu_item;