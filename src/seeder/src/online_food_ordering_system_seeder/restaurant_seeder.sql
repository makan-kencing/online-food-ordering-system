-- ============================================
-- 1. RESTAURANT
-- ============================================
INSERT INTO restaurant
(code, name, description, introduction_date, image_url,
 opening_hour, closing_hour, is_temporarily_closed,
 address_id, created_by_id)
VALUES
    ('RST001', 'Pizza Palace', 'Best pizzas in town',
     CURRENT_TIMESTAMP, '/images/restaurants/pizza-palace.jpg',
     INTERVAL '0 10:00:00' DAY TO SECOND,
     INTERVAL '0 22:00:00' DAY TO SECOND,
     FALSE, 1, 1),

    ('RST002', 'Burger Haven', 'Juicy burgers and fries',
     CURRENT_TIMESTAMP, '/images/restaurants/burger-haven.jpg',
     INTERVAL '0 09:00:00' DAY TO SECOND,
     INTERVAL '0 23:00:00' DAY TO SECOND,
     FALSE, 2, 2),

    ('RST003', 'Cool Drinks Bar', 'Refreshing beverages and shakes',
     CURRENT_TIMESTAMP, '/images/restaurants/drinks-bar.jpg',
     INTERVAL '0 11:00:00' DAY TO SECOND,
     INTERVAL '0 21:00:00' DAY TO SECOND,
     FALSE, 3, 3),

    ('RST004', 'Snack Corner', 'Sides, snacks and quick bites',
     CURRENT_TIMESTAMP, '/images/restaurants/snack-corner.jpg',
     INTERVAL '0 08:00:00' DAY TO SECOND,
     INTERVAL '0 20:00:00' DAY TO SECOND,
     FALSE, 4, 4),

    ('RST005', 'Sweet Tooth', 'Desserts and sweet treats',
     CURRENT_TIMESTAMP, '/images/restaurants/sweet-tooth.jpg',
     INTERVAL '0 12:00:00' DAY TO SECOND,
     INTERVAL '0 22:30:00' DAY TO SECOND,
     FALSE, 5, 5),

    ('RST006', 'Spicy Delight', 'Authentic spicy Asian cuisine',
     CURRENT_TIMESTAMP, '/images/restaurants/spicy-delight.jpg',
     INTERVAL '0 10:30:00' DAY TO SECOND,
     INTERVAL '0 22:30:00' DAY TO SECOND,
     FALSE, 6, 1),

    ('RST007', 'Healthy Bites', 'Fresh salads and healthy meals',
     CURRENT_TIMESTAMP, '/images/restaurants/healthy-bites.jpg',
     INTERVAL '0 09:00:00' DAY TO SECOND,
     INTERVAL '0 20:30:00' DAY TO SECOND,
     FALSE, 7, 2),

    ('RST008', 'Noodle House', 'Traditional noodles and soups',
     CURRENT_TIMESTAMP, '/images/restaurants/noodle-house.jpg',
     INTERVAL '0 10:00:00' DAY TO SECOND,
     INTERVAL '0 21:30:00' DAY TO SECOND,
     FALSE, 8, 3),

    ('RST009', 'Grill Master', 'Grilled meats and BBQ specialties',
     CURRENT_TIMESTAMP, '/images/restaurants/grill-master.jpg',
     INTERVAL '0 11:30:00' DAY TO SECOND,
     INTERVAL '0 23:00:00' DAY TO SECOND,
     FALSE, 9, 4),

    ('RST010', 'Cafe Aroma', 'Coffee, pastries and light meals',
     CURRENT_TIMESTAMP, '/images/restaurants/cafe-aroma.jpg',
     INTERVAL '0 07:30:00' DAY TO SECOND,
     INTERVAL '0 19:30:00' DAY TO SECOND,
     FALSE, 10, 5);

-- ============================================
-- 2. MENU ITEM GROUPS
-- ============================================
INSERT INTO menu_item_group (name, description) VALUES
                                                    ('Rice Dishes', 'Rice based meals and specialties'),
                                                    ('Noodles', 'All noodle based dishes'),
                                                    ('Seafood', 'Fresh seafood selections'),
                                                    ('Grill & BBQ', 'Grilled and barbeque items'),
                                                    ('Street Food', 'Popular street food favorites'),
                                                    ('Vegan Menu', 'Plant based vegan dishes'),
                                                    ('Chef Specials', 'Exclusive chef recommended dishes'),
                                                    ('Seasonal Items', 'Limited seasonal menu items'),
                                                    ('Hot Drinks', 'Coffee, tea and hot beverages'),
                                                    ('Cold Drinks', 'Chilled drinks and smoothies');

-- ============================================
-- 3. MENU ITEMS
-- ============================================
-- Restaurant 1
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 1,
       (SELECT id FROM menu_item_group WHERE name = 'Pizzas'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1','PIZ-PEP-1','PIZ-VEG-1','PIZ-SUP-1');

-- Restaurant 2
INSERT INTO menu_item
SELECT p.id, 2,
       (SELECT id FROM menu_item_group WHERE name = 'Burgers'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('BRG-CHZ-1','BRG-CHK-1','BRG-VEG-1','BRG-DBL-1');

-- Restaurant 3
INSERT INTO menu_item
SELECT p.id, 3,
       (SELECT id FROM menu_item_group WHERE name = 'Beverages'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('BEV-COL-1','BEV-LEM-1','BEV-CHC-1','BEV-ICE-1');

-- Restaurant 4
INSERT INTO menu_item
SELECT p.id, 4,
       (SELECT id FROM menu_item_group WHERE name = 'Sides'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('SIDE-FRY1','SIDE-ONI1','SIDE-WNG1');

-- Restaurant 5
INSERT INTO menu_item
SELECT p.id, 5,
       (SELECT id FROM menu_item_group WHERE name = 'Desserts'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('DESS-CAK1','DESS-ICE1');

-- Restaurant 6
INSERT INTO menu_item
SELECT p.id, 6,
       (SELECT id FROM menu_item_group WHERE name = 'Healthy Choice'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-VEG-1','BRG-VEG-1','BEV-LEM-1','BEV-ICE-1');

-- Restaurant 7
INSERT INTO menu_item
SELECT p.id, 7,
       (SELECT id FROM menu_item_group WHERE name = 'Kids Menu'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1','BEV-LEM-1','SIDE-FRY1','DESS-ICE1');

-- Restaurant 8
INSERT INTO menu_item
SELECT p.id, 8,
       (SELECT id FROM menu_item_group WHERE name = 'Combos'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('BRG-CHZ-1','BEV-COL-1','SIDE-FRY1','DESS-ICE1');

-- Restaurant 9
INSERT INTO menu_item
SELECT p.id, 9,
       (SELECT id FROM menu_item_group WHERE name = 'Specialty'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-SUP-1','BRG-DBL-1','SIDE-WNG1','DESS-CAK1');

-- Restaurant 10
INSERT INTO menu_item
SELECT p.id, 10,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code LIKE 'PIZ-%' THEN 'Pizzas'
                                                 WHEN p.code LIKE 'BRG-%' THEN 'Burgers'
                                                 WHEN p.code LIKE 'BEV-%' THEN 'Beverages'
                                                 WHEN p.code LIKE 'SIDE-%' THEN 'Sides'
                                                 WHEN p.code LIKE 'DESS-%' THEN 'Desserts'
                                                 END),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN (
                 'PIZ-MRG-1','PIZ-PEP-1','PIZ-VEG-1','PIZ-SUP-1',
                 'BRG-CHZ-1','BRG-CHK-1','BRG-VEG-1','BRG-DBL-1',
                 'BEV-COL-1','BEV-LEM-1','BEV-CHC-1','BEV-ICE-1',
                 'SIDE-FRY1','SIDE-ONI1','SIDE-WNG1',
                 'DESS-CAK1','DESS-ICE1'
    );