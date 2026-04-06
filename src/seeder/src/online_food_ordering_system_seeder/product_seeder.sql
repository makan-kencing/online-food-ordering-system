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
-- 1. PRODUCT FEATURES (Global, Reusable)
-- ============================================
INSERT INTO product_feature (name, code, created_by_id) VALUES
-- Sizes
('Regular', 'SIZE_REG', 1),
('Large', 'SIZE_LRG', 1),
('Personal', 'SIZE_PRS', 1),
('Family', 'SIZE_FAM', 1),
('Small', 'SIZE_SML', 1),
('Medium', 'SIZE_MED', 1),

-- Spice Levels
('Mild', 'SPICE_MID', 1),
('Medium Spice', 'SPICE_MED', 1),
('Hot', 'SPICE_HOT', 1),
('Extra Hot', 'SPICE_XHT', 1),
('No Spice', 'SPICE_NON', 1),

-- Crust Types
('Thin Crust', 'CRUST_THN', 1),
('Pan Crust', 'CRUST_PAN', 1),
('Stuffed Crust', 'CRUST_STF', 1),
('Cheese Burst', 'CRUST_CHZ', 1),
('Gluten Free', 'CRUST_GLF', 1),

-- Toppings
('Extra Cheese', 'TOP_EXCHZ', 1),
('Extra Pepperoni', 'TOP_EXPEP', 1),
('Extra Mushroom', 'TOP_EXMSH', 1),
('Extra Onion', 'TOP_EXONI', 1),
('Extra Bacon', 'TOP_EXBAC', 1),
('Extra Jalapeno', 'TOP_EXJAL', 1),

-- Remove Options
('No Onion', 'OPT_NOONI', 1),
('No Garlic', 'OPT_NOGRL', 1),
('No Cheese', 'OPT_NOCHZ', 1),

-- Doneness
('Well Done', 'COOK_WEL', 1),
('Regular Cook', 'COOK_REG', 1),
('Light Cook', 'COOK_LIT', 1),

-- Patty Types
('Beef Patty', 'PTY_BEEF', 1),
('Chicken Patty', 'PTY_CHK', 1),
('Veggie Patty', 'PTY_VEG', 1),
('Double Beef', 'PTY_DBL', 1),

-- Beverage Options
('Regular Ice', 'ICE_REG', 1),
('Less Ice', 'ICE_LESS', 1),
('No Ice', 'ICE_NONE', 1),
('Regular Sugar', 'SUG_REG', 1),
('Less Sugar', 'SUG_LESS', 1),
('No Sugar', 'SUG_NONE', 1);

-- ============================================
-- 2. PRODUCT FEATURE GROUPS (Product-specific)
-- ============================================
-- Pizza groups for MARGHERITA (5 groups)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Pizza Size_PIZ-MRG-1', 1, 1, 1),
                                                                      ('Crust Type_PIZ-MRG-1', 1, 1, 1),
                                                                      ('Spice Level_PIZ-MRG-1', 1, 1, 1),
                                                                      ('Extra Toppings_PIZ-MRG-1', 0, 3, 1),
                                                                      ('Remove Ingredients_PIZ-MRG-1', 0, 2, 1);

-- Pizza groups for PEPPERONI (same structure, different options later)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Pizza Size_PIZ-PEP-1', 1, 1, 1),
                                                                      ('Crust Type_PIZ-PEP-1', 1, 1, 1),
                                                                      ('Spice Level_PIZ-PEP-1', 1, 1, 1),
                                                                      ('Extra Toppings_PIZ-PEP-1', 0, 4, 1),  -- More toppings allowed
                                                                      ('Remove Ingredients_PIZ-PEP-1', 0, 1, 1); -- Fewer remove options

-- Pizza groups for VEGGIE (different spice options)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Pizza Size_PIZ-VEG-1', 1, 1, 1),
                                                                      ('Crust Type_PIZ-VEG-1', 1, 1, 1),
                                                                      ('Spice Level_PIZ-VEG-1', 1, 1, 1),
                                                                      ('Extra Toppings_PIZ-VEG-1', 0, 5, 1),  -- Most toppings allowed
                                                                      ('Remove Ingredients_PIZ-VEG-1', 0, 3, 1);

-- Pizza groups for SUPREME (limited crust options)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Pizza Size_PIZ-SUP-1', 1, 1, 1),
                                                                      ('Crust Type_PIZ-SUP-1', 1, 1, 1),
                                                                      ('Spice Level_PIZ-SUP-1', 1, 1, 1),
                                                                      ('Extra Toppings_PIZ-SUP-1', 0, 4, 1),
                                                                      ('Remove Ingredients_PIZ-SUP-1', 0, 2, 1);

-- Burger groups for CHEESEBURGER
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Burger Size_BRG-CHZ-1', 1, 1, 1),
                                                                      ('Patty Type_BRG-CHZ-1', 1, 1, 1),
                                                                      ('Doneness_BRG-CHZ-1', 1, 1, 1),
                                                                      ('Extra Toppings_BRG-CHZ-1', 0, 4, 1);

-- Burger groups for CHICKEN BURGER (different patty options)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Burger Size_BRG-CHK-1', 1, 1, 1),
                                                                      ('Patty Type_BRG-CHK-1', 1, 1, 1),
                                                                      ('Doneness_BRG-CHK-1', 1, 1, 1),
                                                                      ('Extra Toppings_BRG-CHK-1', 0, 3, 1);  -- Fewer toppings

-- Burger groups for VEGGIE BURGER (limited options)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Burger Size_BRG-VEG-1', 1, 1, 1),
                                                                      ('Patty Type_BRG-VEG-1', 1, 1, 1),
                                                                      ('Doneness_BRG-VEG-1', 1, 1, 1),
                                                                      ('Extra Toppings_BRG-VEG-1', 0, 5, 1);  -- More veggie toppings

-- Burger groups for DOUBLE BACON (premium)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Burger Size_BRG-DBL-1', 1, 1, 1),
                                                                      ('Patty Type_BRG-DBL-1', 1, 1, 1),
                                                                      ('Doneness_BRG-DBL-1', 1, 1, 1),
                                                                      ('Extra Toppings_BRG-DBL-1', 0, 5, 1);

-- Beverage groups for COLA (all options)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Beverage Size_BEV-COL-1', 1, 1, 1),
                                                                      ('Ice Level_BEV-COL-1', 1, 1, 1),
                                                                      ('Sugar Level_BEV-COL-1', 1, 1, 1);

-- Beverage groups for LEMONADE (limited ice/sugar)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Beverage Size_BEV-LEM-1', 1, 1, 1),
                                                                      ('Ice Level_BEV-LEM-1', 1, 1, 1),
                                                                      ('Sugar Level_BEV-LEM-1', 1, 1, 1);

-- Beverage groups for ICE TEA (no sugar option)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
                                                                      ('Beverage Size_BEV-ICE-1', 1, 1, 1),
                                                                      ('Ice Level_BEV-ICE-1', 1, 1, 1),
                                                                      ('Sugar Level_BEV-ICE-1', 1, 1, 1);

-- Beverage groups for MILKSHAKE (size only, no ice/sugar)
INSERT INTO product_feature_group (name, min, max, created_by_id) VALUES
    ('Beverage Size_BEV-CHC-1', 1, 1, 1);

-- ============================================
-- 3. PRODUCT FEATURE GROUP FIELDS (Linking features to product-specific groups)
-- ============================================

-- PIZ-MRG-1: All standard options
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Pizza Size_PIZ-MRG-1' AND pf.name IN ('Regular', 'Large', 'Personal');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Crust Type_PIZ-MRG-1' AND pf.name IN ('Thin Crust', 'Pan Crust', 'Stuffed Crust');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Spice Level_PIZ-MRG-1' AND pf.name IN ('Mild', 'Medium Spice', 'Hot');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_PIZ-MRG-1' AND pf.name IN ('Extra Cheese', 'Extra Mushroom', 'Extra Onion');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Remove Ingredients_PIZ-MRG-1' AND pf.name IN ('No Onion', 'No Garlic');

-- PIZ-PEP-1: Has pepperoni topping (different from Margherita)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Pizza Size_PIZ-PEP-1' AND pf.name IN ('Regular', 'Large', 'Family');  -- Different size options

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Crust Type_PIZ-PEP-1' AND pf.name IN ('Thin Crust', 'Cheese Burst');  -- Limited crust options

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Spice Level_PIZ-PEP-1' AND pf.name IN ('Medium Spice', 'Hot', 'Extra Hot');  -- Different spice range

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_PIZ-PEP-1' AND pf.name IN ('Extra Cheese', 'Extra Pepperoni', 'Extra Mushroom', 'Extra Bacon');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Remove Ingredients_PIZ-PEP-1' AND pf.name IN ('No Garlic');  -- Only one remove option

-- PIZ-VEG-1: Vegetarian focused
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Pizza Size_PIZ-VEG-1' AND pf.name IN ('Personal', 'Regular', 'Large', 'Family');  -- All sizes

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Crust Type_PIZ-VEG-1' AND pf.name IN ('Thin Crust', 'Pan Crust', 'Stuffed Crust', 'Gluten Free');  -- Has gluten free

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Spice Level_PIZ-VEG-1' AND pf.name IN ('No Spice', 'Mild', 'Medium Spice');  -- No hot spice

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_PIZ-VEG-1' AND pf.name IN ('Extra Cheese', 'Extra Mushroom', 'Extra Onion', 'Extra Jalapeno');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Remove Ingredients_PIZ-VEG-1' AND pf.name IN ('No Onion', 'No Garlic', 'No Cheese');

-- PIZ-SUP-1: Premium with all options
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Pizza Size_PIZ-SUP-1' AND pf.name IN ('Regular', 'Large', 'Family');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Crust Type_PIZ-SUP-1' AND pf.name IN ('Pan Crust', 'Stuffed Crust', 'Cheese Burst');  -- Premium crusts only

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Spice Level_PIZ-SUP-1' AND pf.name IN ('Mild', 'Medium Spice', 'Hot', 'Extra Hot');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_PIZ-SUP-1' AND pf.name IN ('Extra Cheese', 'Extra Pepperoni', 'Extra Mushroom', 'Extra Onion', 'Extra Bacon', 'Extra Jalapeno');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Remove Ingredients_PIZ-SUP-1' AND pf.name IN ('No Onion', 'No Garlic');

-- BRG-CHZ-1: Classic beef burger
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Burger Size_BRG-CHZ-1' AND pf.name IN ('Regular', 'Large');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Patty Type_BRG-CHZ-1' AND pf.name IN ('Beef Patty', 'Double Beef');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Doneness_BRG-CHZ-1' AND pf.name IN ('Light Cook', 'Regular Cook', 'Well Done');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_BRG-CHZ-1' AND pf.name IN ('Extra Cheese', 'Extra Onion', 'Extra Bacon');

-- BRG-CHK-1: Chicken burger (no beef options)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Burger Size_BRG-CHK-1' AND pf.name IN ('Regular', 'Large');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Patty Type_BRG-CHK-1' AND pf.name IN ('Chicken Patty');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Doneness_BRG-CHK-1' AND pf.name IN ('Regular Cook', 'Well Done');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_BRG-CHK-1' AND pf.name IN ('Extra Cheese', 'Extra Jalapeno');

-- BRG-VEG-1: Veggie burger
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Burger Size_BRG-VEG-1' AND pf.name IN ('Regular', 'Large');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Patty Type_BRG-VEG-1' AND pf.name IN ('Veggie Patty');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Doneness_BRG-VEG-1' AND pf.name IN ('Regular Cook');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_BRG-VEG-1' AND pf.name IN ('Extra Cheese', 'Extra Mushroom', 'Extra Onion', 'Extra Jalapeno');

-- BRG-DBL-1: Double bacon burger (premium)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Burger Size_BRG-DBL-1' AND pf.name IN ('Large', 'Family');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Patty Type_BRG-DBL-1' AND pf.name IN ('Double Beef');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Doneness_BRG-DBL-1' AND pf.name IN ('Light Cook', 'Regular Cook', 'Well Done');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Extra Toppings_BRG-DBL-1' AND pf.name IN ('Extra Cheese', 'Extra Bacon', 'Extra Onion');

-- BEV-COL-1: Full options
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Beverage Size_BEV-COL-1' AND pf.name IN ('Small', 'Medium', 'Large');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Ice Level_BEV-COL-1' AND pf.name IN ('Regular Ice', 'Less Ice', 'No Ice');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Sugar Level_BEV-COL-1' AND pf.name IN ('Regular Sugar', 'Less Sugar', 'No Sugar');

-- BEV-LEM-1: Limited options (no sugar adjustments for lemonade)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Beverage Size_BEV-LEM-1' AND pf.name IN ('Small', 'Medium');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Ice Level_BEV-LEM-1' AND pf.name IN ('Regular Ice', 'Less Ice');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Sugar Level_BEV-LEM-1' AND pf.name IN ('Regular Sugar');  -- Only regular sugar

-- BEV-ICE-1: No sugar option (unsweetened tea)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Beverage Size_BEV-ICE-1' AND pf.name IN ('Medium', 'Large');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Ice Level_BEV-ICE-1' AND pf.name IN ('Regular Ice', 'No Ice');

INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Sugar Level_BEV-ICE-1' AND pf.name IN ('No Sugar');  -- Only no sugar

-- BEV-CHC-1: Milkshake (size only)
INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
SELECT fg.id, pf.id
FROM product_feature_group fg, product_feature pf
WHERE fg.name = 'Beverage Size_BEV-CHC-1' AND pf.name IN ('Small', 'Medium', 'Large');

-- ============================================
-- 4. PRODUCT CATEGORIES
-- ============================================
-- Parent Categories
INSERT INTO product_category (name, description, parent, created_by_id) VALUES
                                                                            ('Pizzas', 'Delicious pizzas with various toppings', NULL, 1),
                                                                            ('Burgers', 'Juicy burgers with premium ingredients', NULL, 1),
                                                                            ('Beverages', 'Refreshing drinks and beverages', NULL, 1),
                                                                            ('Sides', 'Perfect side dishes', NULL, 1),
                                                                            ('Desserts', 'Sweet treats', NULL, 1);

-- Sub-Categories
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
                                                                                               ('PIZ-MRG-1', 'Margherita Pizza', 'Classic Italian pizza with fresh basil', CURRENT_TIMESTAMP, '/images/pizzas/margherita.jpg', 1),
                                                                                               ('PIZ-PEP-1', 'Pepperoni Pizza', 'Loaded with premium pepperoni', CURRENT_TIMESTAMP, '/images/pizzas/pepperoni.jpg', 1),
                                                                                               ('PIZ-VEG-1', 'Garden Veggie Pizza', 'Fresh farm vegetables', CURRENT_TIMESTAMP, '/images/pizzas/veggie.jpg', 1),
                                                                                               ('PIZ-SUP-1', 'Supreme Pizza', 'Loaded supreme with everything', CURRENT_TIMESTAMP, '/images/pizzas/supreme.jpg', 1),
                                                                                               ('BRG-CHZ-1', 'Classic Cheeseburger', 'Beef patty with melted cheese', CURRENT_TIMESTAMP, '/images/burgers/cheeseburger.jpg', 1),
                                                                                               ('BRG-CHK-1', 'Crispy Chicken Burger', 'Crispy chicken breast with special sauce', CURRENT_TIMESTAMP, '/images/burgers/chicken.jpg', 1),
                                                                                               ('BRG-VEG-1', 'Veggie Supreme Burger', 'Plant-based patty with fresh veggies', CURRENT_TIMESTAMP, '/images/burgers/veggie.jpg', 1),
                                                                                               ('BRG-DBL-1', 'Double Bacon Burger', 'Double beef patty with crispy bacon', CURRENT_TIMESTAMP, '/images/burgers/double-bacon.jpg', 1),
                                                                                               ('BEV-COL-1', 'Cola', 'Classic refreshing cola', CURRENT_TIMESTAMP, '/images/beverages/cola.jpg', 1),
                                                                                               ('BEV-LEM-1', 'Lemonade', 'Fresh squeezed lemonade', CURRENT_TIMESTAMP, '/images/beverages/lemonade.jpg', 1),
                                                                                               ('BEV-CHC-1', 'Chocolate Milkshake', 'Rich creamy chocolate shake', CURRENT_TIMESTAMP, '/images/beverages/choc-shake.jpg', 1),
                                                                                               ('BEV-ICE-1', 'Iced Lemon Tea', 'Refreshing unsweetened iced tea', CURRENT_TIMESTAMP, '/images/beverages/iced-tea.jpg', 1),
                                                                                               ('SIDE-FRY1', 'French Fries', 'Crispy golden fries', CURRENT_TIMESTAMP, '/images/sides/fries.jpg', 1),
                                                                                               ('SIDE-ONI1', 'Onion Rings', 'Crispy onion rings', CURRENT_TIMESTAMP, '/images/sides/onion-rings.jpg', 1),
                                                                                               ('SIDE-WNG1', 'Chicken Wings', 'Spicy buffalo wings', CURRENT_TIMESTAMP, '/images/sides/wings.jpg', 1),
                                                                                               ('DESS-CAK1', 'Chocolate Lava Cake', 'Warm molten chocolate cake', CURRENT_TIMESTAMP, '/images/desserts/lava-cake.jpg', 1),
                                                                                               ('DESS-ICE1', 'Ice Cream Sundae', 'Vanilla ice cream with chocolate sauce', CURRENT_TIMESTAMP, '/images/desserts/sundae.jpg', 1);

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
((SELECT id FROM product WHERE code = 'PIZ-SUP-1'), (SELECT id FROM product_category WHERE name = 'Specialty'), CURRENT_TIMESTAMP, NULL, false),

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
((SELECT id FROM product WHERE code = 'BEV-ICE-1'), (SELECT id FROM product_category WHERE name = 'Juices'), CURRENT_TIMESTAMP, NULL, false),

-- Side classifications
((SELECT id FROM product WHERE code = 'SIDE-FRY1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'SIDE-ONI1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'SIDE-WNG1'), (SELECT id FROM product_category WHERE name = 'Sides'), CURRENT_TIMESTAMP, NULL, true),

-- Dessert classifications 
((SELECT id FROM product WHERE code = 'DESS-CAK1'), (SELECT id FROM product_category WHERE name = 'Desserts'), CURRENT_TIMESTAMP, NULL, true),
((SELECT id FROM product WHERE code = 'DESS-ICE1'), (SELECT id FROM product_category WHERE name = 'Desserts'), CURRENT_TIMESTAMP, NULL, true);

-- ============================================
-- 7. PRODUCT ATTRIBUTES (Link products to their groups)
-- ============================================

-- PIZ-MRG-1 attributes
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-MRG-1' AND fg.name LIKE 'Pizza Size_PIZ-MRG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-MRG-1' AND fg.name LIKE 'Crust Type_PIZ-MRG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-MRG-1' AND fg.name LIKE 'Spice Level_PIZ-MRG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-MRG-1' AND fg.name LIKE 'Extra Toppings_PIZ-MRG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-MRG-1' AND fg.name LIKE 'Remove Ingredients_PIZ-MRG-1';

-- PIZ-PEP-1 attributes
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-PEP-1' AND fg.name LIKE 'Pizza Size_PIZ-PEP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-PEP-1' AND fg.name LIKE 'Crust Type_PIZ-PEP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-PEP-1' AND fg.name LIKE 'Spice Level_PIZ-PEP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-PEP-1' AND fg.name LIKE 'Extra Toppings_PIZ-PEP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-PEP-1' AND fg.name LIKE 'Remove Ingredients_PIZ-PEP-1';

-- PIZ-VEG-1 attributes
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-VEG-1' AND fg.name LIKE 'Pizza Size_PIZ-VEG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-VEG-1' AND fg.name LIKE 'Crust Type_PIZ-VEG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-VEG-1' AND fg.name LIKE 'Spice Level_PIZ-VEG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-VEG-1' AND fg.name LIKE 'Extra Toppings_PIZ-VEG-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-VEG-1' AND fg.name LIKE 'Remove Ingredients_PIZ-VEG-1';

-- PIZ-SUP-1 attributes
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-SUP-1' AND fg.name LIKE 'Pizza Size_PIZ-SUP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-SUP-1' AND fg.name LIKE 'Crust Type_PIZ-SUP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-SUP-1' AND fg.name LIKE 'Spice Level_PIZ-SUP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-SUP-1' AND fg.name LIKE 'Extra Toppings_PIZ-SUP-1';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'PIZ-SUP-1' AND fg.name LIKE 'Remove Ingredients_PIZ-SUP-1';

-- Burger attributes (similar pattern for all burgers)
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1')
  AND fg.name LIKE 'Burger Size_' || p.code || '%';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1')
  AND fg.name LIKE 'Patty Type_' || p.code || '%';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1')
  AND fg.name LIKE 'Doneness_' || p.code || '%';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1')
  AND fg.name LIKE 'Extra Toppings_' || p.code || '%';

-- Beverage attributes
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BEV-COL-1', 'BEV-LEM-1', 'BEV-ICE-1')
  AND fg.name LIKE 'Beverage Size_' || p.code || '%';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BEV-COL-1', 'BEV-LEM-1', 'BEV-ICE-1')
  AND fg.name LIKE 'Ice Level_' || p.code || '%';

INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code IN ('BEV-COL-1', 'BEV-LEM-1', 'BEV-ICE-1')
  AND fg.name LIKE 'Sugar Level_' || p.code || '%';

-- Milkshake (size only)
INSERT INTO product_attribute (product_id, product_feature_group_id)
SELECT p.id, fg.id
FROM product p, product_feature_group fg
WHERE p.code = 'BEV-CHC-1' AND fg.name LIKE 'Beverage Size_BEV-CHC-1';

-- ============================================
-- 8. MENU ITEM GROUPS
-- ============================================
INSERT INTO menu_item_group (name, description) VALUES
                                                    ('Pizzas', 'All pizza menu items - classic and specialty'),
                                                    ('Burgers', 'Premium burger selection'),
                                                    ('Beverages', 'Refreshing drinks and beverages'),
                                                    ('Sides', 'Perfect side dishes to complement your meal'),
                                                    ('Desserts', 'Sweet treats for dessert lovers'),
                                                    ('Specialty', 'Chef specials and limited time offers'),
                                                    ('Combos', 'Value meal combinations'),
                                                    ('Breakfast', 'Morning breakfast items'),
                                                    ('Healthy Choice', 'Low calorie and healthy options'),
                                                    ('Kids Menu', 'Smaller portions for children');

/*-- ============================================
-- 9. MENU ITEMS
-- ============================================

-- Restaurant 1 (Flagship - Full menu with everything)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 1,
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
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-PEP-1', 'PIZ-VEG-1', 'PIZ-SUP-1',
                 'BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1',
                 'BEV-COL-1', 'BEV-LEM-1', 'BEV-CHC-1', 'BEV-ICE-1',
                 'SIDE-FRY1', 'SIDE-ONI1', 'SIDE-WNG1',
                 'DESS-CAK1', 'DESS-ICE1');

-- Restaurant 2 (Casual Dining - No specialty items, limited burgers)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 2,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code LIKE 'PIZ-%' THEN 'Pizzas'
                                                 WHEN p.code LIKE 'BRG-%' AND p.code NOT IN ('BRG-DBL-1') THEN 'Burgers'
                                                 WHEN p.code LIKE 'BEV-%' AND p.code != 'BEV-CHC-1' THEN 'Beverages'
                                                 WHEN p.code LIKE 'SIDE-%' AND p.code != 'SIDE-WNG1' THEN 'Sides'
                                                 WHEN p.code LIKE 'DESS-%' AND p.code = 'DESS-ICE1' THEN 'Desserts'
                                                 END),
       CASE
           WHEN p.code = 'PIZ-VEG-1' THEN TRUE  -- Temporarily unavailable
           WHEN p.code = 'BRG-CHK-1' THEN TRUE  -- Temporarily unavailable
           ELSE FALSE
           END,
       CASE
           WHEN p.code = 'PIZ-VEG-1' THEN CURRENT_TIMESTAMP + INTERVAL '5' DAY
           WHEN p.code = 'BRG-CHK-1' THEN CURRENT_TIMESTAMP + INTERVAL '3' DAY
           ELSE CURRENT_TIMESTAMP
           END,
       NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-PEP-1', 'PIZ-VEG-1', 'PIZ-SUP-1',
                 'BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1',
                 'BEV-COL-1', 'BEV-LEM-1', 'BEV-ICE-1',
                 'SIDE-FRY1', 'SIDE-ONI1',
                 'DESS-ICE1');

-- Restaurant 3 (Premium - Only premium/limited items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 3,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code = 'PIZ-SUP-1' THEN 'Specialty'
                                                 WHEN p.code = 'BRG-DBL-1' THEN 'Specialty'
                                                 WHEN p.code = 'BEV-CHC-1' THEN 'Beverages'
                                                 WHEN p.code = 'SIDE-WNG1' THEN 'Sides'
                                                 WHEN p.code = 'DESS-CAK1' THEN 'Desserts'
                                                 END),
       FALSE,
       CURRENT_TIMESTAMP,
       CASE
           WHEN p.code = 'PIZ-SUP-1' THEN CURRENT_TIMESTAMP + INTERVAL '1' MONTH  -- Limited time offer
           ELSE NULL
           END
FROM product p
WHERE p.code IN ('PIZ-SUP-1', 'BRG-DBL-1', 'BEV-CHC-1', 'SIDE-WNG1', 'DESS-CAK1');

-- Restaurant 4 (Budget - Only value items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 4,
       (SELECT id FROM menu_item_group WHERE name = 'Combos'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1', 'BRG-CHZ-1', 'BEV-COL-1', 'SIDE-FRY1');

-- Restaurant 5 (Family-friendly - Has kids menu items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 5,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code IN ('PIZ-VEG-1', 'PIZ-MRG-1') THEN 'Kids Menu'
                                                 WHEN p.code = 'BEV-LEM-1' THEN 'Beverages'
                                                 WHEN p.code = 'SIDE-FRY1' THEN 'Sides'
                                                 WHEN p.code = 'DESS-ICE1' THEN 'Kids Menu'
                                                 END),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-VEG-1', 'BEV-LEM-1', 'SIDE-FRY1', 'DESS-ICE1');

-- Restaurant 6 (Health-conscious - Only healthy options)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 6,
       (SELECT id FROM menu_item_group WHERE name = 'Healthy Choice'),
       FALSE, CURRENT_TIMESTAMP, NULL
FROM product p
WHERE p.code IN ('PIZ-VEG-1', 'BEV-LEM-1', 'BEV-ICE-1', 'SIDE-FRY1', 'DESS-CAK1');

-- Restaurant 7 (Breakfast focused - Limited evening items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 7,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code IN ('PIZ-MRG-1', 'PIZ-VEG-1') THEN 'Pizzas'
                                                 WHEN p.code IN ('BEV-COL-1', 'BEV-LEM-1') THEN 'Beverages'
                                                 END),
       TRUE,  -- Unavailable during breakfast hours
       CURRENT_TIMESTAMP + INTERVAL '10' HOUR,  -- Available after 10 AM
       NULL
FROM product p
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-VEG-1', 'BEV-COL-1', 'BEV-LEM-1');

-- Restaurant 8 (Late night - Only quick items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 8,
       (SELECT id FROM menu_item_group WHERE name =
                                             CASE
                                                 WHEN p.code = 'BRG-CHZ-1' THEN 'Burgers'
                                                 WHEN p.code = 'BEV-COL-1' THEN 'Beverages'
                                                 WHEN p.code = 'SIDE-FRY1' THEN 'Sides'
                                                 END),
       FALSE,
       CURRENT_TIMESTAMP + INTERVAL '18' HOUR,  -- Starts at 6 PM
       CURRENT_TIMESTAMP + INTERVAL '6' HOUR + INTERVAL '1' DAY  -- Ends at 6 AM
FROM product p
WHERE p.code IN ('BRG-CHZ-1', 'BEV-COL-1', 'SIDE-FRY1');

-- Restaurant 9 (Pop-up store - Temporary, limited items)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
SELECT p.id, 9,
       (SELECT id FROM menu_item_group WHERE name = 'Specialty'),
       FALSE,
       CURRENT_TIMESTAMP + INTERVAL '7' DAY,  -- Opens next week
       CURRENT_TIMESTAMP + INTERVAL '30' DAY   -- Closes in 30 days
FROM product p
WHERE p.code IN ('PIZ-SUP-1', 'BRG-DBL-1', 'BEV-CHC-1', 'DESS-CAK1');

-- Restaurant 10 (Delivery kitchen - Full menu always available)
INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
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
WHERE p.code IN ('PIZ-MRG-1', 'PIZ-PEP-1', 'PIZ-VEG-1', 'PIZ-SUP-1',
                 'BRG-CHZ-1', 'BRG-CHK-1', 'BRG-VEG-1', 'BRG-DBL-1',
                 'BEV-COL-1', 'BEV-LEM-1', 'BEV-CHC-1', 'BEV-ICE-1',
                 'SIDE-FRY1', 'SIDE-ONI1', 'SIDE-WNG1',
                 'DESS-CAK1', 'DESS-ICE1');
*/

COMMIT;