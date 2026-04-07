-- 1. RESTAURANT
INSERT INTO RESTAURANT (NAME, CODE, INTRODUCTION_DATE, DESCRIPTION, OPENING_HOUR, CLOSING_HOUR, IS_TEMPORARILY_CLOSED,
                        ADDRESS_ID,
                        CREATED_BY_ID)
VALUES ('Pizza Palace Downtown', 'R1', TIMESTAMP '2025-01-01 0:0:0', 'Best pizza in town', INTERVAL '10' HOUR,
        INTERVAL '22' HOUR, FALSE, 1, 2),
       ('Burger King Express', 'R2', TIMESTAMP '2025-02-03 0:0:0', 'Fast and delicious burgers', INTERVAL '9' HOUR,
        INTERVAL '23' HOUR, FALSE, 2, 3),
       ('Healthy Bites Cafe', 'R3', TIMESTAMP '2025-06-02 0:0:0', 'Organic and healthy options', INTERVAL '8' HOUR,
        INTERVAL '20' HOUR, FALSE, 3, 4),
       ('Tasty Corner', 'R4', TIMESTAMP '2025-03-01 0:0:0', 'Affordable family meals', INTERVAL '11' HOUR,
        INTERVAL '21' HOUR, FALSE, 4, 5),
       ('Pizza Hut Express', 'R5', TIMESTAMP '2025-08-01 0:0:0', 'Famous pan pizzas', INTERVAL '10:30' HOUR TO MINUTE,
        INTERVAL '22:30' HOUR TO MINUTE, FALSE, 5, 6),
       ('Sweet Treats Dessert', 'R6', TIMESTAMP '2025-01-12 0:0:0', 'Delicious desserts', INTERVAL '12' HOUR,
        INTERVAL '22' HOUR, FALSE, 6, 7),
       ('Healthy Pizza Co', 'R7', TIMESTAMP '2025-02-23 0:0:0', 'Gluten free pizza', INTERVAL '10' HOUR,
        INTERVAL '21' HOUR, FALSE, 7, 8),
       ('Coffee Corner', 'R8', TIMESTAMP '2025-01-22 0:0:0', 'Premium coffee', INTERVAL '7' HOUR, INTERVAL '20' HOUR,
        FALSE, 8, 9),
       ('Classic Pizza House', 'R9', TIMESTAMP '2025-01-16 0:0:0', 'Traditional pizza', INTERVAL '11' HOUR,
        INTERVAL '23' HOUR, FALSE, 9, 10),
       ('Tea House', 'R10', TIMESTAMP '2026-01-03 0:0:0', 'Fine tea selection', INTERVAL '9' HOUR, INTERVAL '19' HOUR,
        FALSE, 10, 11),
       ('Noodle King', 'R11', TIMESTAMP '2025-11-04 0:0:0', 'Handmade noodles', INTERVAL '10' HOUR, INTERVAL '22' HOUR,
        FALSE, 11, 12),
       ('Sushi Master', 'R12', TIMESTAMP '2025-09-07 0:0:0', 'Fresh Japanese', INTERVAL '11:30' HOUR TO MINUTE,
        INTERVAL '21:30' HOUR TO MINUTE,
        FALSE, 12, 13);

-- 2. MENU_ITEM_GROUP
INSERT INTO MENU_ITEM_GROUP (NAME, DESCRIPTION)
VALUES ('Pizzas', 'All pizza menu items'),
       ('Burgers', 'Burger selection'),
       ('Beverages', 'Drinks and beverages'),
       ('Sides', 'Side dishes'),
       ('Desserts', 'Sweet treats'),
       ('Coffee', 'Hot beverages'),
       ('Tea', 'Tea selection'),
       ('Noodles', 'Noodle dishes'),
       ('Sushi', 'Japanese sushi'),
       ('Rice Bowls', 'Rice based dishes');

-- 3. PRODUCT_FEATURE
INSERT INTO PRODUCT_FEATURE (NAME, CODE, CREATED_BY_ID)
VALUES
-- Member 1 features (Restaurant 1 - Pizza Palace)
('Regular', 'R1_SIZE_REG', 1),
('Large', 'R1_SIZE_LRG', 1),
('Small', 'R1_SIZE_SML', 1),
('Medium', 'R1_SIZE_MED', 1),
('Personal', 'R1_SIZE_PRS', 1),
('Family', 'R1_SIZE_FAM', 1),
('Thin Crust', 'R1_CRUST_THIN', 1),
('Pan Crust', 'R1_CRUST_PAN', 1),
('Stuffed Crust', 'R1_CRUST_STUFFED', 1),
('Mild', 'R1_SPICE_MILD', 1),
('Medium Spice', 'R1_SPICE_MED', 1),
('Hot', 'R1_SPICE_HOT', 1),
('Extra Cheese', 'R1_TOP_CHEESE', 1),
('Extra Pepperoni', 'R1_TOP_PEPPERONI', 1),
('Extra Mushroom', 'R1_TOP_MUSHROOM', 1),
('Extra Onion', 'R1_TOP_ONION', 1),
('No Onion', 'R1_OPT_NOONION', 1),
('No Garlic', 'R1_OPT_NOGARLIC', 1),

-- Member 2 features (Restaurant 2 - Burger Express)
('Regular', 'R2_SIZE_REG', 2),
('Large', 'R2_SIZE_LRG', 2),
('Family', 'R2_SIZE_FAM', 2),
('Thin Crust', 'R2_CRUST_THIN', 2),
('Cheese Burst', 'R2_CRUST_CHEESE', 2),
('Mild', 'R2_SPICE_MILD', 2),
('Hot', 'R2_SPICE_HOT', 2),
('Extra Hot', 'R2_SPICE_EXTRA', 2),
('Beef Patty', 'R2_PTY_BEEF', 2),
('Chicken Patty', 'R2_PTY_CHICKEN', 2),
('Double Beef', 'R2_PTY_DOUBLE', 2),
('Veggie Patty', 'R2_PTY_VEGGIE', 2),
('Extra Cheese', 'R2_TOP_CHEESE', 2),
('Extra Bacon', 'R2_TOP_BACON', 2),
('Extra Onion', 'R2_TOP_ONION', 2),
('Well Done', 'R2_COOK_WELL', 2),
('Regular Cook', 'R2_COOK_REG', 2),
('Light Cook', 'R2_COOK_LIGHT', 2),

-- Member 3 features (Restaurant 3 - Healthy Bites)
('Small', 'R3_SIZE_SML', 3),
('Medium', 'R3_SIZE_MED', 3),
('Large', 'R3_SIZE_LRG', 3),
('Regular Ice', 'R3_ICE_REG', 3),
('Less Ice', 'R3_ICE_LESS', 3),
('No Ice', 'R3_ICE_NONE', 3),
('Regular Sugar', 'R3_SUG_REG', 3),
('Less Sugar', 'R3_SUG_LESS', 3),
('No Sugar', 'R3_SUG_NONE', 3),
('Lemon Slice', 'R3_OPT_LEMON', 3),
('Mint Leaves', 'R3_OPT_MINT', 3),
('Honey', 'R3_OPT_HONEY', 3),

-- Member 4 features (Restaurant 4 - Tasty Corner)
('Regular', 'R4_SIZE_REG', 4),
('Large', 'R4_SIZE_LRG', 4),
('Ketchup', 'R4_SAUCE_KETCHUP', 4),
('Mayonnaise', 'R4_SAUCE_MAYO', 4),
('BBQ Sauce', 'R4_SAUCE_BBQ', 4),
('Chili Sauce', 'R4_SAUCE_CHILI', 4),
('Well Done', 'R4_COOK_WELL', 4),
('Regular Cook', 'R4_COOK_REG', 4),
('Extra Cheese', 'R4_TOP_CHEESE', 4),
('Extra Bacon', 'R4_TOP_BACON', 4),

-- Member 5 features (Restaurant 5 - Pizza Hut Express)
('Medium', 'R5_SIZE_MED', 5),
('Large', 'R5_SIZE_LRG', 5),
('Extra Large', 'R5_SIZE_XL', 5),
('Stuffed Crust', 'R5_CRUST_STUFFED', 5),
('Cheese Burst', 'R5_CRUST_CHEESE', 5),
('Mild', 'R5_SPICE_MILD', 5),
('Medium Spice', 'R5_SPICE_MED', 5),
('Hot', 'R5_SPICE_HOT', 5),
('Extra Hot', 'R5_SPICE_EXTRA', 5),
('Extra Cheese', 'R5_TOP_CHEESE', 5),
('Extra Pepperoni', 'R5_TOP_PEPPERONI', 5),
('Extra Mushroom', 'R5_TOP_MUSHROOM', 5),
('Extra Sausage', 'R5_TOP_SAUSAGE', 5),

-- Member 6 features (Restaurant 6 - Sweet Treats)
('Small', 'R6_SIZE_SML', 6),
('Medium', 'R6_SIZE_MED', 6),
('Large', 'R6_SIZE_LRG', 6),
('Vanilla', 'R6_FLAV_VANILLA', 6),
('Chocolate', 'R6_FLAV_CHOCOLATE', 6),
('Strawberry', 'R6_FLAV_STRAWBERRY', 6),
('Whipped Cream', 'R6_TOP_WHIPPED', 6),
('Cherry', 'R6_TOP_CHERRY', 6),
('Sprinkles', 'R6_TOP_SPRINKLES', 6),
('Hot Fudge', 'R6_TOP_FUDGE', 6),

-- Member 7 features (Restaurant 7 - Healthy Pizza Co)
('Regular', 'R7_SIZE_REG', 7),
('Large', 'R7_SIZE_LRG', 7),
('Thin Crust', 'R7_CRUST_THIN', 7),
('Gluten Free', 'R7_CRUST_GF', 7),
('Cauliflower', 'R7_CRUST_CAULI', 7),
('No Spice', 'R7_SPICE_NONE', 7),
('Mild', 'R7_SPICE_MILD', 7),
('Extra Cheese', 'R7_TOP_CHEESE', 7),
('Extra Mushroom', 'R7_TOP_MUSHROOM', 7),
('Extra Spinach', 'R7_TOP_SPINACH', 7),
('No Onion', 'R7_OPT_NOONION', 7),
('No Garlic', 'R7_OPT_NOGARLIC', 7),

-- Member 8 features (Restaurant 8 - Coffee Corner)
('Small', 'R8_SIZE_SML', 8),
('Medium', 'R8_SIZE_MED', 8),
('Large', 'R8_SIZE_LRG', 8),
('Espresso Shot', 'R8_ESP_SHOT', 8),
('Double Espresso', 'R8_ESP_DOUBLE', 8),
('Soy Milk', 'R8_MILK_SOY', 8),
('Oat Milk', 'R8_MILK_OAT', 8),
('Almond Milk', 'R8_MILK_ALMOND', 8),
('Vanilla Syrup', 'R8_SYRUP_VANILLA', 8),
('Caramel Syrup', 'R8_SYRUP_CARAMEL', 8),
('Hazelnut Syrup', 'R8_SYRUP_HAZELNUT', 8),

-- Member 9 features (Restaurant 9 - Classic Pizza House)
('Regular', 'R9_SIZE_REG', 9),
('Large', 'R9_SIZE_LRG', 9),
('Thin Crust', 'R9_CRUST_THIN', 9),
('Pan Crust', 'R9_CRUST_PAN', 9),
('Mild', 'R9_SPICE_MILD', 9),
('Medium Spice', 'R9_SPICE_MED', 9),
('Hot', 'R9_SPICE_HOT', 9),
('Extra Cheese', 'R9_TOP_CHEESE', 9),
('Extra Pepperoni', 'R9_TOP_PEPPERONI', 9),
('Extra Sausage', 'R9_TOP_SAUSAGE', 9),
('Extra Mushroom', 'R9_TOP_MUSHROOM', 9),

-- Member 10 features (Restaurant 10 - Tea House)
('Small', 'R10_SIZE_SML', 10),
('Medium', 'R10_SIZE_MED', 10),
('Large', 'R10_SIZE_LRG', 10),
('Green Tea', 'R10_TEA_GREEN', 10),
('Black Tea', 'R10_TEA_BLACK', 10),
('Oolong Tea', 'R10_TEA_OOLONG', 10),
('Jasmine Tea', 'R10_TEA_JASMINE', 10),
('Honey', 'R10_OPT_HONEY', 10),
('Lemon', 'R10_OPT_LEMON', 10),
('Regular Ice', 'R10_ICE_REG', 10),
('No Ice', 'R10_ICE_NONE', 10),
('Regular Sugar', 'R10_SUG_REG', 10),
('No Sugar', 'R10_SUG_NONE', 10),

-- Member 11 features (Restaurant 11 - Noodle King)
('Small', 'R11_SIZE_SML', 11),
('Medium', 'R11_SIZE_MED', 11),
('Large', 'R11_SIZE_LRG', 11),
('Egg Noodles', 'R11_NOOD_EGG', 11),
('Rice Noodles', 'R11_NOOD_RICE', 11),
('Mild', 'R11_SPICE_MILD', 11),
('Medium Spice', 'R11_SPICE_MED', 11),
('Hot', 'R11_SPICE_HOT', 11),
('Extra Noodles', 'R11_EXTRA_NOODLES', 11),
('Extra Meat', 'R11_EXTRA_MEAT', 11),
('Extra Vegetable', 'R11_EXTRA_VEG', 11),

-- Member 12 features (Restaurant 12 - Sushi Master)
('Small', 'R12_SIZE_SML', 12),
('Medium', 'R12_SIZE_MED', 12),
('Large', 'R12_SIZE_LRG', 12),
('Soy Sauce', 'R12_DIP_SOY', 12),
('Wasabi', 'R12_DIP_WASABI', 12),
('Ginger', 'R12_DIP_GINGER', 12),
('Salmon', 'R12_FISH_SALMON', 12),
('Tuna', 'R12_FISH_TUNA', 12),
('Shrimp', 'R12_FISH_SHRIMP', 12),
('Eel', 'R12_FISH_EEL', 12),
('Avocado', 'R12_VEG_AVOCADO', 12),
('Cucumber', 'R12_VEG_CUCUMBER', 12);

-- 4. PRODUCT_CATEGORY (36 records - 3 per restaurant)
INSERT INTO PRODUCT_CATEGORY (NAME, DESCRIPTION, PARENT, CREATED_BY_ID)
VALUES
-- Restaurant 1 categories
('Pizzas', 'Delicious pizzas', NULL, 1),
('Veg Pizzas', 'Vegetarian options', NULL, 1),
('NonVeg Pizzas', 'Meat options', NULL, 1),
-- Restaurant 2 categories
('Burgers', 'Juicy burgers', NULL, 2),
('Chicken Burgers', 'Chicken options', NULL, 2),
('Beef Burgers', 'Beef options', NULL, 2),
-- Restaurant 3 categories
('Beverages', 'Refreshing drinks', NULL, 3),
('Carbonated', 'Soda drinks', NULL, 3),
('Juices', 'Fresh juices', NULL, 3),
-- Restaurant 4 categories
('Sides', 'Perfect sides', NULL, 4),
('Fries', 'Potato sides', NULL, 4),
('Dips', 'Sauces', NULL, 4),
-- Restaurant 5 categories
('Pizzas', 'Specialty pizzas', NULL, 5),
('Premium', 'Premium selection', NULL, 5),
('Classic', 'Classic pizzas', NULL, 5),
-- Restaurant 6 categories
('Desserts', 'Sweet treats', NULL, 6),
('Ice Cream', 'Frozen desserts', NULL, 6),
('Cakes', 'Fresh cakes', NULL, 6),
-- Restaurant 7 categories
('Pizzas', 'Healthy pizzas', NULL, 7),
('Gluten Free', 'GF options', NULL, 7),
('Low Carb', 'Keto options', NULL, 7),
-- Restaurant 8 categories
('Coffee', 'Hot beverages', NULL, 8),
('Espresso', 'Coffee shots', NULL, 8),
('Latte', 'Milk coffee', NULL, 8),
-- Restaurant 9 categories
('Pizzas', 'Classic pizzas', NULL, 9),
('Specialty', 'Chef specials', NULL, 9),
('Signature', 'House specials', NULL, 9),
-- Restaurant 10 categories
('Tea', 'Hot tea', NULL, 10),
('Iced Tea', 'Cold tea', NULL, 10),
('Herbal Tea', 'Caffeine free', NULL, 10),
-- Restaurant 11 categories
('Noodles', 'Noodle dishes', NULL, 11),
('Soup Noodles', 'Broth based', NULL, 11),
('Dry Noodles', 'No broth', NULL, 11),
-- Restaurant 12 categories
('Sushi', 'Japanese sushi', NULL, 12),
('Maki Rolls', 'Rolled sushi', NULL, 12),
('Nigiri', 'Hand pressed', NULL, 12);

-- 5. PRODUCT (36 records - 3 per restaurant)
INSERT INTO PRODUCT (CODE, NAME, DESCRIPTION, INTRODUCTION_DATE, IMAGE_URL, CREATED_BY_ID)
VALUES
-- Restaurant 1 products
('R1PIZ001', 'Margherita Pizza', 'Classic Italian pizza with fresh basil', DATE '2024-01-15',
 '/images/r1/margherita.jpg', 1),
('R1PIZ002', 'Pepperoni Pizza', 'Loaded with premium pepperoni', DATE '2024-01-20', '/images/r1/pepperoni.jpg', 1),
('R1PIZ003', 'Garden Veggie', 'Fresh farm vegetables', DATE '2024-02-01', '/images/r1/veggie.jpg', 1),

-- Restaurant 2 products
('R2BRG001', 'Classic Cheeseburger', 'Beef patty with melted cheese', DATE '2024-02-10', '/images/r2/cheeseburger.jpg',
 2),
('R2BRG002', 'Crispy Chicken Burger', 'Crispy chicken breast', DATE '2024-02-15', '/images/r2/chicken.jpg', 2),
('R2BRG003', 'Double Bacon Burger', 'Double beef with bacon', DATE '2024-03-01', '/images/r2/double-bacon.jpg', 2),

-- Restaurant 3 products
('R3BEV001', 'Cola', 'Classic refreshing cola', DATE '2024-03-10', '/images/r3/cola.jpg', 3),
('R3BEV002', 'Lemonade', 'Fresh squeezed lemonade', DATE '2024-03-15', '/images/r3/lemonade.jpg', 3),
('R3BEV003', 'Iced Lemon Tea', 'Refreshing iced tea', DATE '2024-04-01', '/images/r3/iced-tea.jpg', 3),

-- Restaurant 4 products
('R4SIDE01', 'French Fries', 'Crispy golden fries', DATE '2024-04-10', '/images/r4/fries.jpg', 4),
('R4SIDE02', 'Onion Rings', 'Crispy onion rings', DATE '2024-04-15', '/images/r4/onion-rings.jpg', 4),
('R4SIDE03', 'Chicken Wings', 'Spicy buffalo wings', DATE '2024-05-01', '/images/r4/wings.jpg', 4),

-- Restaurant 5 products
('R5PIZ001', 'Supreme Pizza', 'Loaded with everything', DATE '2024-05-10', '/images/r5/supreme.jpg', 5),
('R5PIZ002', 'BBQ Chicken Pizza', 'Grilled chicken with BBQ sauce', DATE '2024-05-15', '/images/r5/bbq-chicken.jpg', 5),
('R5PIZ003', 'Hawaiian Pizza', 'Ham and pineapple', DATE '2024-06-01', '/images/r5/hawaiian.jpg', 5),

-- Restaurant 6 products
('R6DES001', 'Chocolate Lava Cake', 'Warm molten chocolate', DATE '2024-06-10', '/images/r6/lava-cake.jpg', 6),
('R6DES002', 'Ice Cream Sundae', 'Vanilla with chocolate sauce', DATE '2024-06-15', '/images/r6/sundae.jpg', 6),
('R6DES003', 'Cheesecake', 'New York style', DATE '2024-07-01', '/images/r6/cheesecake.jpg', 6),

-- Restaurant 7 products
('R7PIZ001', 'Gluten Free Margherita', 'GF crust with fresh basil', DATE '2024-07-10', '/images/r7/gf-margherita.jpg',
 7),
('R7PIZ002', 'Veggie Supreme GF', 'GF crust with vegetables', DATE '2024-07-15', '/images/r7/gf-veggie.jpg', 7),
('R7PIZ003', 'Cauliflower Crust Pizza', 'Low carb option', DATE '2024-08-01', '/images/r7/cauliflower.jpg', 7),

-- Restaurant 8 products
('R8COF001', 'Espresso', 'Strong coffee shot', DATE '2024-08-10', '/images/r8/espresso.jpg', 8),
('R8COF002', 'Cappuccino', 'Espresso with steamed milk', DATE '2024-08-15', '/images/r8/cappuccino.jpg', 8),
('R8COF003', 'Latte', 'Smooth coffee with milk', DATE '2024-09-01', '/images/r8/latte.jpg', 8),

-- Restaurant 9 products
('R9PIZ001', 'Meat Lovers Pizza', 'Loaded with meats', DATE '2024-09-10', '/images/r9/meat-lovers.jpg', 9),
('R9PIZ002', 'Four Cheese Pizza', 'Mozzarella, cheddar, parmesan, blue', DATE '2024-09-15',
 '/images/r9/four-cheese.jpg', 9),
('R9PIZ003', 'Mushroom Truffle Pizza', 'Wild mushrooms with truffle oil', DATE '2024-10-01', '/images/r9/truffle.jpg',
 9),

-- Restaurant 10 products
('R10TEA01', 'Green Tea', 'Fresh brewed green tea', DATE '2024-10-10', '/images/r10/green-tea.jpg', 10),
('R10TEA02', 'Black Tea', 'Classic black tea', DATE '2024-10-15', '/images/r10/black-tea.jpg', 10),
('R10TEA03', 'Jasmine Tea', 'Fragrant jasmine tea', DATE '2024-11-01', '/images/r10/jasmine-tea.jpg', 10),

-- Restaurant 11 products
('R11NOD01', 'Wonton Noodle Soup', 'Pork wonton with egg noodles', DATE '2024-11-10', '/images/r11/wonton.jpg', 11),
('R11NOD02', 'Beef Noodle Soup', 'Braised beef with noodles', DATE '2024-11-15', '/images/r11/beef-noodle.jpg', 11),
('R11NOD03', 'Dry Curry Noodles', 'Spicy dry curry noodles', DATE '2024-12-01', '/images/r11/curry-noodle.jpg', 11),

-- Restaurant 12 products
('R12SUS01', 'California Roll', 'Crab, avocado, cucumber', DATE '2024-12-10', '/images/r12/california.jpg', 12),
('R12SUS02', 'Salmon Nigiri', 'Fresh salmon over rice', DATE '2024-12-15', '/images/r12/salmon.jpg', 12),
('R12SUS03', 'Dragon Roll', 'Eel, avocado, cucumber', DATE '2024-12-20', '/images/r12/dragon.jpg', 12);

-- 6. PRODUCT_FEATURE_GROUP
DECLARE
    v_product_code VARCHAR2(20);
BEGIN
    -- Restaurant 1 (3 products × 5 groups = 15)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R1PIZ00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 1);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Crust_' || v_product_code, 1, 1, 1);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Spice_' || v_product_code, 1, 1, 1);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Toppings_' || v_product_code, 0, 5, 1);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Remove_' || v_product_code, 0, 3, 1);
        END LOOP;

    -- Restaurant 2 (3 products × 4 groups = 12)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R2BRG00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 2);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Patty_' || v_product_code, 1, 1, 2);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Doneness_' || v_product_code, 1, 1, 2);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Toppings_' || v_product_code, 0, 4, 2);
        END LOOP;

    -- Restaurant 3 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R3BEV00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 3);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Ice_' || v_product_code, 1, 1, 3);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Sugar_' || v_product_code, 1, 1, 3);
        END LOOP;

    -- Restaurant 4 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R4SIDE0' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 4);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Cook_' || v_product_code, 1, 1, 4);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Dip_' || v_product_code, 0, 2, 4);
        END LOOP;

    -- Restaurant 5 (3 products × 4 groups = 12)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R5PIZ00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 5);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Crust_' || v_product_code, 1, 1, 5);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Spice_' || v_product_code, 1, 1, 5);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Toppings_' || v_product_code, 0, 5, 5);
        END LOOP;

    -- Restaurant 6 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R6DES00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 6);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Flavor_' || v_product_code, 1, 1, 6);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Toppings_' || v_product_code, 0, 3, 6);
        END LOOP;

    -- Restaurant 7 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R7PIZ00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 7);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Crust_' || v_product_code, 1, 1, 7);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Spice_' || v_product_code, 1, 1, 7);
        END LOOP;

    -- Restaurant 8 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R8COF00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 8);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Type_' || v_product_code, 1, 1, 8);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Milk_' || v_product_code, 0, 1, 8);
        END LOOP;

    -- Restaurant 9 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R9PIZ00' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 9);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Crust_' || v_product_code, 1, 1, 9);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Spice_' || v_product_code, 1, 1, 9);
        END LOOP;

    -- Restaurant 10 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R10TEA0' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 10);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Ice_' || v_product_code, 1, 1, 10);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Sweetener_' || v_product_code, 0, 1, 10);
        END LOOP;

    -- Restaurant 11 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R11NOD0' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 11);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Noodle_' || v_product_code, 1, 1, 11);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Spice_' || v_product_code, 1, 1, 11);
        END LOOP;

    -- Restaurant 12 (3 products × 3 groups = 9)
    FOR i IN 1..3
        LOOP
            v_product_code := 'R12SUS0' || i;
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Size_' || v_product_code, 1, 1, 12);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Type_' || v_product_code, 1, 1, 12);
            INSERT INTO product_feature_group (name, min, max, created_by_id)
            VALUES ('Dip_' || v_product_code, 0, 2, 12);
        END LOOP;
END;
/

-- 7. PRODUCT_FEATURE_GROUP_FIELD 
DECLARE
    v_created_by     NUMBER;
    v_counter        NUMBER := 0;
    v_max_group_id   NUMBER;
    v_max_feature_id NUMBER;
BEGIN
    SELECT MAX(id) INTO v_max_group_id FROM product_feature_group;
    SELECT MAX(id) INTO v_max_feature_id FROM product_feature;

    FOR rec IN (SELECT id, name, created_by_id FROM product_feature_group ORDER BY id)
        LOOP
            v_created_by := rec.created_by_id;

            -- Size groups
            IF rec.name LIKE 'Size_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE name IN ('Small', 'Medium', 'Large', 'Regular', 'Personal', 'Family', 'Extra Large')
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Crust groups
            IF rec.name LIKE 'Crust_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE (name LIKE '%Crust' OR name IN ('Gluten Free', 'Cauliflower', 'Cheese Burst'))
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Spice groups
            IF rec.name LIKE 'Spice_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE name IN ('Mild', 'Medium Spice', 'Hot', 'Extra Hot', 'No Spice', 'Korean Spicy')
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Toppings groups
            IF rec.name LIKE 'Toppings_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE name LIKE 'Extra%'
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Ice/Sugar groups
            IF rec.name LIKE 'Ice_%' OR rec.name LIKE 'Sugar_%' OR rec.name LIKE 'Sweetener_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE (name LIKE '%Ice%' OR name LIKE '%Sugar%' OR
                                    name IN ('Honey', 'Lemon Slice', 'Mint Leaves'))
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Patty groups
            IF rec.name LIKE 'Patty_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE name LIKE '%Patty'
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;

            -- Doneness groups
            IF rec.name LIKE 'Doneness_%' OR rec.name LIKE 'Cook_%' THEN
                FOR feat IN (SELECT id
                             FROM product_feature
                             WHERE name IN ('Well Done', 'Regular Cook', 'Light Cook')
                               AND created_by_id = v_created_by)
                    LOOP
                        BEGIN
                            INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                            VALUES (rec.id, feat.id);
                            v_counter := v_counter + 1;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN NULL;
                        END;
                    END LOOP;
            END IF;
        END LOOP;

    FOR i IN 1..200
        LOOP
            DECLARE
                v_gid      NUMBER;
                v_fid      NUMBER;
                v_g_exists NUMBER;
                v_f_exists NUMBER;
            BEGIN
                v_gid := MOD(i, v_max_group_id) + 1;
                v_fid := MOD(i, v_max_feature_id) + 1;

                SELECT COUNT(*) INTO v_g_exists FROM product_feature_group WHERE id = v_gid;
                SELECT COUNT(*) INTO v_f_exists FROM product_feature WHERE id = v_fid;

                IF v_g_exists > 0 AND v_f_exists > 0 THEN
                    INSERT INTO product_feature_group_field (product_feature_group_id, product_feature_id)
                    VALUES (v_gid, v_fid);
                    v_counter := v_counter + 1;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;

    DBMS_OUTPUT.PUT_LINE('PRODUCT_FEATURE_GROUP_FIELD records inserted: ' || v_counter);
END;
/

-- 8. PRODUCT_ATTRIBUTE
DECLARE
    v_product_code   VARCHAR2(20);
    v_created_by     NUMBER;
    v_counter        NUMBER := 0;
    v_max_product_id NUMBER;
    v_max_group_id   NUMBER;
BEGIN
    SELECT MAX(id) INTO v_max_product_id FROM product;
    SELECT MAX(id) INTO v_max_group_id FROM product_feature_group;

    FOR prod IN (SELECT id, code, created_by_id FROM product)
        LOOP
            v_product_code := prod.code;
            v_created_by := prod.created_by_id;

            FOR grp IN (SELECT id
                        FROM product_feature_group
                        WHERE name LIKE '%' || v_product_code || '%'
                          AND created_by_id = v_created_by)
                LOOP
                    BEGIN
                        INSERT INTO product_attribute (product_id, product_feature_group_id)
                        VALUES (prod.id, grp.id);
                        v_counter := v_counter + 1;
                    EXCEPTION
                        WHEN DUP_VAL_ON_INDEX THEN NULL;
                    END;
                END LOOP;
        END LOOP;

    FOR i IN 1..200
        LOOP
            DECLARE
                v_pid      NUMBER := MOD(i, v_max_product_id) + 1;
                v_gid      NUMBER := MOD(i, v_max_group_id) + 1;
                v_p_exists NUMBER;
                v_g_exists NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_p_exists FROM product WHERE id = v_pid;
                SELECT COUNT(*) INTO v_g_exists FROM product_feature_group WHERE id = v_gid;

                IF v_p_exists > 0 AND v_g_exists > 0 THEN
                    INSERT INTO product_attribute (product_id, product_feature_group_id)
                    VALUES (v_pid, v_gid);
                END IF;
            END;
        END LOOP;
END;
/

-- 9. PRODUCT_CATEGORY_CLASSIFICATION
DECLARE
    v_category_id     NUMBER;
    v_created_by      NUMBER;
    v_counter         NUMBER := 0;
    v_max_product_id  NUMBER;
    v_max_category_id NUMBER;
BEGIN
    SELECT MAX(id) INTO v_max_product_id FROM product;
    SELECT MAX(id) INTO v_max_category_id FROM product_category;

    FOR prod IN (SELECT id, created_by_id FROM product)
        LOOP
            v_created_by := prod.created_by_id;

            BEGIN
                SELECT id
                INTO v_category_id
                FROM product_category
                WHERE created_by_id = v_created_by
                  AND parent IS NULL
                  AND ROWNUM = 1;

                INSERT INTO product_category_classification (product_id, product_category_id, from_date, thru_date, is_primary)
                VALUES (prod.id, v_category_id, CURRENT_TIMESTAMP, NULL, TRUE);
                v_counter := v_counter + 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;

            FOR cat IN (SELECT id
                        FROM product_category
                        WHERE created_by_id = v_created_by
                          AND parent IS NOT NULL
                          AND ROWNUM <= 2)
                LOOP
                    INSERT INTO product_category_classification (product_id, product_category_id, from_date, thru_date, is_primary)
                    VALUES (prod.id, cat.id, CURRENT_TIMESTAMP, NULL, FALSE);
                    v_counter := v_counter + 1;
                END LOOP;
        END LOOP;

    FOR i IN 1..200
        LOOP
            DECLARE
                v_pid      NUMBER := MOD(i, v_max_product_id) + 1;
                v_cid      NUMBER := MOD(i, v_max_category_id) + 1;
                v_p_exists NUMBER;
                v_c_exists NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_p_exists FROM product WHERE id = v_pid;
                SELECT COUNT(*) INTO v_c_exists FROM product_category WHERE id = v_cid;

                IF v_p_exists > 0 AND v_c_exists > 0 THEN
                    INSERT INTO product_category_classification (product_id, product_category_id, from_date, thru_date, is_primary)
                    VALUES (v_pid,
                            v_cid,
                            TO_TIMESTAMP('2023-' || LPAD(MOD(i, 12) + 1, 2, '0') || '-01 10:00:00',
                                         'YYYY-MM-DD HH24:MI:SS'),
                            CASE
                                WHEN MOD(i, 3) = 0
                                    THEN TO_TIMESTAMP('2024-' || LPAD(MOD(i, 12) + 1, 2, '0') || '-01 10:00:00',
                                                      'YYYY-MM-DD HH24:MI:SS')
                                ELSE NULL
                                END,
                            CASE WHEN MOD(i, 5) = 0 THEN TRUE ELSE FALSE END);
                END IF;
            END;
        END LOOP;

    DBMS_OUTPUT.PUT_LINE('PRODUCT_CATEGORY_CLASSIFICATION records inserted: ' || v_counter);
END;
/

-- 10. MENU_ITEM
DECLARE
    v_group_id          NUMBER;
    v_max_product_id    NUMBER;
    v_max_restaurant_id NUMBER;
    v_max_group_id      NUMBER;
BEGIN
    SELECT MAX(id) INTO v_max_product_id FROM product;
    SELECT MAX(id) INTO v_max_restaurant_id FROM restaurant;
    SELECT MAX(id) INTO v_max_group_id FROM menu_item_group;

    FOR rest IN (SELECT id, created_by_id FROM restaurant)
        LOOP
            BEGIN
                SELECT id
                INTO v_group_id
                FROM menu_item_group
                WHERE name = (
                    CASE rest.created_by_id
                        WHEN 1 THEN 'Pizzas'
                        WHEN 2 THEN 'Burgers'
                        WHEN 3 THEN 'Beverages'
                        WHEN 4 THEN 'Sides'
                        WHEN 5 THEN 'Pizzas'
                        WHEN 6 THEN 'Desserts'
                        WHEN 7 THEN 'Pizzas'
                        WHEN 8 THEN 'Coffee'
                        WHEN 9 THEN 'Pizzas'
                        WHEN 10 THEN 'Tea'
                        WHEN 11 THEN 'Noodles'
                        WHEN 12 THEN 'Sushi'
                        END
                    );
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_group_id := 1;
            END;

            FOR prod IN (SELECT id FROM product WHERE created_by_id = rest.created_by_id)
                LOOP
                    BEGIN
                        INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date,
                                               thru_date)
                        VALUES (prod.id, rest.id, v_group_id, FALSE, DATE '2024-01-01', NULL);
                    EXCEPTION
                        WHEN DUP_VAL_ON_INDEX THEN NULL;
                    END;
                END LOOP;
        END LOOP;

    FOR i IN 1..200
        LOOP
            DECLARE
                v_pid      NUMBER := MOD(i, v_max_product_id) + 1;
                v_rid      NUMBER := MOD(i, v_max_restaurant_id) + 1;
                v_gid      NUMBER := MOD(i, v_max_group_id) + 1;
                v_p_exists NUMBER;
                v_r_exists NUMBER;
                v_g_exists NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_p_exists FROM product WHERE id = v_pid;
                SELECT COUNT(*) INTO v_r_exists FROM restaurant WHERE id = v_rid;
                SELECT COUNT(*) INTO v_g_exists FROM menu_item_group WHERE id = v_gid;

                IF v_p_exists > 0 AND v_r_exists > 0 AND v_g_exists > 0 THEN
                    INSERT INTO menu_item (product_id, restaurant_id, group_id, is_unavailable, from_date, thru_date)
                    VALUES (v_pid,
                            v_rid,
                            v_gid,
                            CASE WHEN MOD(i, 10) = 0 THEN TRUE ELSE FALSE END,
                            TO_DATE('2024-' || LPAD(MOD(i, 12) + 1, 2, '0') || '-01', 'YYYY-MM-DD'),
                            CASE
                                WHEN MOD(i, 5) = 0
                                    THEN TO_DATE('2024-' || LPAD(MOD(i, 12) + 1, 2, '0') || '-28', 'YYYY-MM-DD')
                                ELSE NULL
                                END);
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;
END;
/

COMMIT;

-- COUNT for each Tables
SELECT 'RESTAURANT' AS table_name, COUNT(*) AS record_count
FROM RESTAURANT
UNION ALL
SELECT 'MENU_ITEM_GROUP', COUNT(*)
FROM MENU_ITEM_GROUP
UNION ALL
SELECT 'PRODUCT', COUNT(*)
FROM PRODUCT
UNION ALL
SELECT 'PRODUCT_CATEGORY', COUNT(*)
FROM PRODUCT_CATEGORY
UNION ALL
SELECT 'PRODUCT_FEATURE', COUNT(*)
FROM PRODUCT_FEATURE
UNION ALL
SELECT 'PRODUCT_FEATURE_GROUP', COUNT(*)
FROM PRODUCT_FEATURE_GROUP
UNION ALL
SELECT 'PRODUCT_FEATURE_GROUP_FIELD', COUNT(*)
FROM PRODUCT_FEATURE_GROUP_FIELD
UNION ALL
SELECT 'PRODUCT_ATTRIBUTE', COUNT(*)
FROM PRODUCT_ATTRIBUTE
UNION ALL
SELECT 'PRODUCT_CATEGORY_CLASSIFICATION', COUNT(*)
FROM PRODUCT_CATEGORY_CLASSIFICATION
UNION ALL
SELECT 'MENU_ITEM', COUNT(*)
FROM MENU_ITEM
ORDER BY table_name;