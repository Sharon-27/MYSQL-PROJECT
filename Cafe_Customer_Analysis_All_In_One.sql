

-- ============================================================
-- FILE: Database/01_Create_Database.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 1: DATABASE CREATION
-- MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS cafe_customer_analysis;
CREATE DATABASE cafe_customer_analysis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE cafe_customer_analysis;


-- ============================================================
-- FILE: Database/02_Create_Tables.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 2: TABLE CREATION
-- Schema follows the supplied ER diagram.
-- ============================================================

USE cafe_customer_analysis;

-- =========================
-- CATEGORIES
-- =========================
CREATE TABLE Categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description   VARCHAR(255)
);

-- =========================
-- EMPLOYEES
-- =========================
CREATE TABLE Employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(50) NOT NULL,
    phone       VARCHAR(15),
    hire_date   DATE NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================
-- CUSTOMERS
-- =========================
CREATE TABLE Customers (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    phone          VARCHAR(15),
    date_of_birth  DATE,
    gender         ENUM('Male','Female','Other','Prefer Not To Say'),
    join_date      DATE NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    loyalty_points INT NOT NULL DEFAULT 0,
    city           VARCHAR(100)
);

-- =========================
-- PRODUCTS
-- =========================
CREATE TABLE Products (
    product_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    description  VARCHAR(255),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    category_id  INT NOT NULL
);

-- =========================
-- ORDERS
-- =========================
CREATE TABLE Orders (
    order_id       INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT NOT NULL,
    employee_id    INT NOT NULL,
    order_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status   ENUM('Pending','Completed','Cancelled','Refunded') NOT NULL DEFAULT 'Pending',
    total_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    final_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    notes          VARCHAR(255)
);

-- =========================
-- ORDER ITEMS
-- =========================
CREATE TABLE OrderItems (
    order_item_id  INT AUTO_INCREMENT PRIMARY KEY,
    line_no        INT NOT NULL,
    order_id       INT NOT NULL,
    product_id     INT NOT NULL,
    quantity       INT NOT NULL,
    unit_price     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_price    DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- =========================
-- PAYMENTS
-- One order -> one payment as shown in the supplied ER diagram.
-- The UNIQUE constraint is added later in 04_Constraints.sql.
-- =========================
CREATE TABLE Payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    order_id       INT NOT NULL,
    payment_method ENUM('Cash','Card','UPI','Wallet') NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    payment_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_status ENUM('Pending','Paid','Failed','Refunded') NOT NULL DEFAULT 'Pending',
    transaction_id VARCHAR(100),
    notes          VARCHAR(255)
);

-- =========================
-- AUDIT TABLES
-- Supporting tables for triggers.
-- =========================
CREATE TABLE ProductPriceAudit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    changed_at DATETIME
);

CREATE TABLE OrderStatusAudit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at DATETIME
);


-- ============================================================
-- FILE: Database/04_Constraints.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 3: CONSTRAINTS AND FOREIGN KEYS
-- ============================================================

USE cafe_customer_analysis;

-- Category name must be unique.
ALTER TABLE Categories
    ADD CONSTRAINT uq_categories_name UNIQUE (category_name);

-- Customer email/phone are unique where supplied.
ALTER TABLE Customers
    ADD CONSTRAINT uq_customers_email UNIQUE (email),
    ADD CONSTRAINT uq_customers_phone UNIQUE (phone),
    ADD CONSTRAINT chk_customers_loyalty CHECK (loyalty_points >= 0);

-- Product price must not be negative.
ALTER TABLE Products
    ADD CONSTRAINT chk_products_price CHECK (price >= 0),
    ADD CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES Categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- Orders.
ALTER TABLE Orders
    ADD CONSTRAINT chk_orders_total CHECK (total_amount >= 0),
    ADD CONSTRAINT chk_orders_discount CHECK (discount_amount >= 0),
    ADD CONSTRAINT chk_orders_final CHECK (final_amount >= 0),
    ADD CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_orders_employee
        FOREIGN KEY (employee_id)
        REFERENCES Employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- Order item integrity.
ALTER TABLE OrderItems
    ADD CONSTRAINT uq_order_line UNIQUE (order_id, line_no),
    ADD CONSTRAINT chk_orderitems_line CHECK (line_no > 0),
    ADD CONSTRAINT chk_orderitems_quantity CHECK (quantity > 0),
    ADD CONSTRAINT chk_orderitems_unit_price CHECK (unit_price >= 0),
    ADD CONSTRAINT chk_orderitems_discount CHECK (discount_amount >= 0),
    ADD CONSTRAINT chk_orderitems_total CHECK (total_price >= 0),
    ADD CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- One order -> one payment according to the supplied ER diagram.
ALTER TABLE Payments
    ADD CONSTRAINT uq_payments_order UNIQUE (order_id),
    ADD CONSTRAINT chk_payments_amount CHECK (amount >= 0),
    ADD CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE;

-- Audit-table foreign keys.
ALTER TABLE ProductPriceAudit
    ADD CONSTRAINT fk_priceaudit_product
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

ALTER TABLE OrderStatusAudit
    ADD CONSTRAINT fk_statusaudit_order
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE;


-- ============================================================
-- FILE: Indexes/Cafe_Indexes.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 4: INDEXES
-- Indexes are based on the joins, filters, grouping, and reporting
-- queries used in this project.
-- ============================================================

USE cafe_customer_analysis;

-- Foreign-key / JOIN indexes
CREATE INDEX idx_products_category
    ON Products(category_id);

CREATE INDEX idx_orders_customer
    ON Orders(customer_id);

CREATE INDEX idx_orders_employee
    ON Orders(employee_id);

CREATE INDEX idx_orderitems_order
    ON OrderItems(order_id);

CREATE INDEX idx_orderitems_product
    ON OrderItems(product_id);

CREATE INDEX idx_payments_order
    ON Payments(order_id);

-- Frequently filtered/sorted columns
CREATE INDEX idx_customers_city
    ON Customers(city);

CREATE INDEX idx_customers_join_date
    ON Customers(join_date);

CREATE INDEX idx_orders_date
    ON Orders(order_date);

CREATE INDEX idx_orders_status
    ON Orders(order_status);

CREATE INDEX idx_payments_method_status
    ON Payments(payment_method, payment_status);

-- Composite indexes for common analytical filters
CREATE INDEX idx_orders_status_date
    ON Orders(order_status, order_date);

CREATE INDEX idx_orderitems_product_order
    ON OrderItems(product_id, order_id);

-- Audit-table indexes
CREATE INDEX idx_priceaudit_product_date
    ON ProductPriceAudit(product_id, changed_at);

CREATE INDEX idx_statusaudit_order_date
    ON OrderStatusAudit(order_id, changed_at);

-- Verification examples:
-- SHOW INDEX FROM Products;
-- SHOW INDEX FROM Orders;
-- SHOW INDEX FROM OrderItems;
-- SHOW INDEX FROM Payments;


-- ============================================================
-- FILE: Database/03_Insert_Data.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 5: SAMPLE DATA
-- The values match the supplied ER structure.
-- Order-item unit_price and total_price are included in seed data
-- so this file can be run before the trigger file.
-- ============================================================

USE cafe_customer_analysis;

-- =========================
-- CATEGORIES
-- =========================
INSERT INTO Categories (category_name, description) VALUES
('Coffee', 'Hot and cold coffee beverages'),
('Tea', 'Tea and tea-based beverages'),
('Snacks', 'Savory quick-service snacks'),
('Desserts', 'Cakes, pastries and sweet items'),
('Breakfast', 'Breakfast and light morning meals'),
('Sandwiches', 'Prepared sandwiches and wraps'),
('Beverages', 'Non-coffee cold and fresh beverages'),
('Healthy', 'Health-focused food and beverage options');

-- =========================
-- EMPLOYEES
-- =========================
INSERT INTO Employees (name, role, phone, hire_date, is_active) VALUES
('Arjun Kumar', 'Cashier', '9000000001', '2024-01-15', TRUE),
('Meera Rao', 'Barista', '9000000002', '2024-03-10', TRUE),
('Kiran Reddy', 'Manager', '9000000003', '2023-07-01', TRUE),
('Ananya Singh', 'Barista', '9000000004', '2025-01-12', TRUE),
('Rahul Das', 'Cashier', '9000000005', '2025-02-20', TRUE),
('Sneha Iyer', 'Barista', '9000000006', '2025-05-05', TRUE),
('Vivek Sharma', 'Manager', '9000000007', '2022-11-18', TRUE),
('Pooja Nair', 'Cashier', '9000000008', '2026-01-10', TRUE);

-- =========================
-- CUSTOMERS
-- =========================
INSERT INTO Customers
(name, email, phone, date_of_birth, gender, join_date, is_active, loyalty_points, city)
VALUES
('Ravi Kumar', 'ravi.kumar@example.com', '9100000001', '1998-02-14', 'Male', '2025-01-10', TRUE, 420, 'Visakhapatnam'),
('Priya Sharma', 'priya.sharma@example.com', '9100000002', '1997-07-21', 'Female', '2025-01-18', TRUE, 680, 'Hyderabad'),
('Arun Patel', 'arun.patel@example.com', '9100000003', '1995-11-03', 'Male', '2025-02-02', TRUE, 250, 'Ahmedabad'),
('Sneha Reddy', 'sneha.reddy@example.com', '9100000004', '1999-04-12', 'Female', '2025-02-15', TRUE, 910, 'Visakhapatnam'),
('Vikram Singh', 'vikram.singh@example.com', '9100000005', '1994-09-08', 'Male', '2025-03-01', TRUE, 120, 'Bengaluru'),
('Anjali Rao', 'anjali.rao@example.com', '9100000006', '2000-01-25', 'Female', '2025-03-12', TRUE, 540, 'Hyderabad'),
('Karthik Varma', 'karthik.varma@example.com', '9100000007', '1996-06-19', 'Male', '2025-03-20', TRUE, 310, 'Chennai'),
('Neha Gupta', 'neha.gupta@example.com', '9100000008', '1998-12-30', 'Female', '2025-04-04', TRUE, 760, 'Pune'),
('Suresh Naidu', 'suresh.naidu@example.com', '9100000009', '1993-03-11', 'Male', '2025-04-15', TRUE, 80, 'Visakhapatnam'),
('Divya Menon', 'divya.menon@example.com', '9100000010', '1999-08-17', 'Female', '2025-05-03', TRUE, 470, 'Kochi'),
('Manoj Verma', 'manoj.verma@example.com', '9100000011', '1992-10-22', 'Male', '2025-05-18', TRUE, 190, 'Delhi'),
('Asha Kapoor', 'asha.kapoor@example.com', '9100000012', '1997-01-09', 'Female', '2025-06-01', TRUE, 610, 'Mumbai'),
('Nikhil Joshi', 'nikhil.joshi@example.com', '9100000013', '1996-05-27', 'Male', '2025-06-18', TRUE, 330, 'Pune'),
('Lakshmi Devi', 'lakshmi.devi@example.com', '9100000014', '1995-02-05', 'Female', '2025-07-02', TRUE, 720, 'Chennai'),
('Rohit Mehta', 'rohit.mehta@example.com', '9100000015', '1998-11-15', 'Male', '2025-07-20', TRUE, 155, 'Mumbai'),
('Swathi Rao', 'swathi.rao@example.com', '9100000016', '2001-03-29', 'Female', '2025-08-10', TRUE, 500, 'Visakhapatnam'),
('Ajay Kumar', 'ajay.kumar@example.com', '9100000017', '1994-12-02', 'Male', '2025-09-01', TRUE, 90, 'Hyderabad'),
('Keerthi Shah', 'keerthi.shah@example.com', '9100000018', '1999-06-11', 'Female', '2025-09-14', TRUE, 840, 'Ahmedabad'),
('Harish Babu', 'harish.babu@example.com', '9100000019', '1993-07-07', 'Male', '2025-10-01', TRUE, 270, 'Bengaluru'),
('Megha Roy', 'megha.roy@example.com', '9100000020', '2000-09-19', 'Female', '2025-10-18', TRUE, 390, 'Kolkata');

-- =========================
-- PRODUCTS
-- =========================
INSERT INTO Products
(product_name, price, description, is_active, category_id)
VALUES
('Espresso', 120.00, 'Single shot espresso', TRUE, 1),
('Cappuccino', 160.00, 'Espresso with steamed milk and foam', TRUE, 1),
('Cafe Latte', 170.00, 'Smooth espresso with steamed milk', TRUE, 1),
('Mocha', 190.00, 'Chocolate-flavored coffee', TRUE, 1),
('Cold Coffee', 180.00, 'Chilled blended coffee', TRUE, 1),
('Masala Tea', 90.00, 'Indian spiced tea', TRUE, 2),
('Green Tea', 100.00, 'Light green tea', TRUE, 2),
('Lemon Tea', 95.00, 'Refreshing lemon tea', TRUE, 2),
('Veg Puff', 80.00, 'Crispy vegetable puff', TRUE, 3),
('Samosa', 70.00, 'Spiced potato samosa', TRUE, 3),
('French Fries', 140.00, 'Crispy potato fries', TRUE, 3),
('Chocolate Cake', 220.00, 'Chocolate layered cake', TRUE, 4),
('Cheesecake', 260.00, 'Classic creamy cheesecake', TRUE, 4),
('Blueberry Muffin', 150.00, 'Fresh blueberry muffin', TRUE, 4),
('Pancakes', 210.00, 'Stack of pancakes with syrup', TRUE, 5),
('Idli Breakfast', 130.00, 'Steamed idli breakfast plate', TRUE, 5),
('Veg Sandwich', 180.00, 'Grilled vegetable sandwich', TRUE, 6),
('Chicken Sandwich', 240.00, 'Grilled chicken sandwich', TRUE, 6),
('Fresh Lime Soda', 110.00, 'Fresh lime soda', TRUE, 7),
('Mango Smoothie', 190.00, 'Fresh mango smoothie', TRUE, 7),
('Fruit Bowl', 200.00, 'Seasonal fresh fruit bowl', TRUE, 8),
('Granola Bowl', 230.00, 'Granola with fruits and yogurt', TRUE, 8),
('Americano', 130.00, 'Espresso with hot water', TRUE, 1),
('Chai Latte', 150.00, 'Tea with steamed milk', TRUE, 2),
('Brownie', 170.00, 'Chocolate brownie', TRUE, 4);

-- =========================
-- ORDERS
-- total_amount/final_amount are seeded consistently with items.
-- =========================
INSERT INTO Orders
(customer_id, employee_id, order_date, order_status, total_amount, discount_amount, final_amount, notes)
VALUES
(1,1,'2026-01-05 09:15:00','Completed',430.00,0.00,430.00,'Morning coffee order'),
(2,2,'2026-01-06 10:20:00','Completed',370.00,20.00,350.00,'Loyalty discount'),
(3,1,'2026-01-10 13:05:00','Completed',320.00,0.00,320.00,NULL),
(4,3,'2026-01-12 17:40:00','Completed',520.00,40.00,480.00,'Evening snack order'),
(5,4,'2026-01-15 08:30:00','Completed',340.00,0.00,340.00,'Breakfast'),
(1,5,'2026-02-02 09:45:00','Completed',470.00,40.00,430.00,'Repeat customer'),
(6,2,'2026-02-05 11:10:00','Completed',490.00,0.00,490.00,NULL),
(7,6,'2026-02-08 14:25:00','Completed',460.00,10.00,450.00,NULL),
(8,7,'2026-02-14 18:05:00','Completed',550.00,50.00,500.00,NULL),
(9,1,'2026-02-18 16:35:00','Completed',310.00,0.00,310.00,NULL),
(10,2,'2026-02-22 12:15:00','Completed',495.00,20.00,475.00,NULL),
(11,4,'2026-03-01 09:05:00','Completed',350.00,0.00,350.00,NULL),
(12,5,'2026-03-04 10:50:00','Completed',450.00,30.00,420.00,NULL),
(13,6,'2026-03-07 13:30:00','Completed',580.00,0.00,580.00,NULL),
(14,7,'2026-03-10 19:20:00','Completed',495.00,40.00,455.00,NULL),
(15,1,'2026-03-15 15:10:00','Completed',340.00,0.00,340.00,NULL),
(16,2,'2026-03-20 08:45:00','Completed',410.00,20.00,390.00,NULL),
(17,3,'2026-03-25 12:40:00','Completed',520.00,0.00,520.00,NULL),
(18,4,'2026-04-02 10:05:00','Completed',600.00,20.00,580.00,NULL),
(1,5,'2026-04-05 17:15:00','Completed',540.00,60.00,480.00,'Repeat customer'),
(2,6,'2026-04-09 09:35:00','Completed',490.00,0.00,490.00,NULL),
(4,7,'2026-04-12 18:20:00','Completed',560.00,70.00,490.00,'Repeat customer'),
(6,1,'2026-04-18 13:50:00','Completed',370.00,0.00,370.00,NULL),
(8,2,'2026-05-03 11:25:00','Completed',510.00,20.00,490.00,NULL),
(10,3,'2026-05-10 16:45:00','Completed',410.00,0.00,410.00,NULL),
(12,4,'2026-05-18 19:10:00','Completed',490.00,40.00,450.00,NULL),
(14,5,'2026-06-01 09:25:00','Completed',510.00,40.00,470.00,NULL),
(16,6,'2026-06-08 12:10:00','Completed',445.00,0.00,445.00,NULL),
(18,7,'2026-06-15 17:55:00','Completed',550.00,50.00,500.00,NULL),
(20,8,'2026-06-22 14:05:00','Completed',350.00,0.00,350.00,NULL),
(3,1,'2026-07-02 10:15:00','Completed',550.00,10.00,540.00,NULL),
(5,2,'2026-07-08 18:40:00','Completed',560.00,30.00,530.00,NULL),
(7,3,'2026-07-15 13:20:00','Completed',430.00,0.00,430.00,NULL),
(9,4,'2026-07-22 09:55:00','Completed',340.00,0.00,340.00,NULL),
(11,5,'2026-08-01 12:35:00','Completed',520.00,20.00,500.00,NULL),
(13,6,'2026-08-08 16:20:00','Completed',430.00,0.00,430.00,NULL),
(15,7,'2026-08-15 18:05:00','Completed',560.00,80.00,480.00,NULL),
(17,8,'2026-08-22 10:30:00','Completed',510.00,0.00,510.00,NULL),
(19,1,'2026-08-28 14:45:00','Completed',525.00,10.00,515.00,NULL),
(1,2,'2026-09-02 09:10:00','Completed',540.00,80.00,460.00,'High-value repeat customer'),
(2,3,'2026-09-05 11:55:00','Completed',550.00,30.00,520.00,NULL),
(4,4,'2026-09-10 17:25:00','Completed',440.00,20.00,420.00,NULL),
(6,5,'2026-09-14 13:05:00','Completed',520.00,0.00,520.00,NULL),
(8,6,'2026-09-18 18:15:00','Completed',480.00,20.00,460.00,NULL),
(12,7,'2026-09-20 09:40:00','Completed',500.00,60.00,440.00,NULL),
(14,8,'2026-09-22 15:30:00','Completed',540.00,10.00,530.00,NULL),
(18,1,'2026-09-25 19:05:00','Pending',440.00,0.00,440.00,'Payment pending'),
(20,2,'2026-09-26 12:20:00','Cancelled',0.00,0.00,0.00,'Order cancelled'),
(16,3,'2026-09-27 10:15:00','Completed',520.00,10.00,510.00,NULL),
(20,3,'2026-09-28 11:20:00','Completed',530.00,20.00,510.00,'Weekend cafe order');

-- =========================
-- ORDER ITEMS
-- Each order has 1-3 items.
-- total_price = quantity * unit_price - discount_amount.
-- =========================
INSERT INTO OrderItems
(line_no, order_id, product_id, quantity, unit_price, discount_amount, total_price)
VALUES
(1,1,2,1,160.00,0.00,160.00),
(2,1,9,2,80.00,0.00,160.00),
(3,1,19,1,110.00,0.00,110.00),
(1,2,3,1,170.00,0.00,170.00),
(2,2,12,1,220.00,20.00,200.00),
(1,3,11,1,140.00,0.00,140.00),
(2,3,17,1,180.00,0.00,180.00),
(1,4,4,1,190.00,0.00,190.00),
(2,4,13,1,260.00,0.00,260.00),
(3,4,10,1,70.00,0.00,70.00),
(1,5,15,1,210.00,0.00,210.00),
(2,5,16,1,130.00,0.00,130.00),
(1,6,5,1,180.00,0.00,180.00),
(2,6,18,1,240.00,0.00,240.00),
(3,6,6,1,90.00,40.00,50.00),
(1,7,20,1,190.00,0.00,190.00),
(2,7,22,1,230.00,0.00,230.00),
(3,7,7,1,100.00,30.00,70.00),
(1,8,1,1,120.00,0.00,120.00),
(2,8,4,1,190.00,0.00,190.00),
(3,8,14,1,150.00,0.00,150.00),
(1,9,12,1,220.00,0.00,220.00),
(2,9,13,1,260.00,0.00,260.00),
(3,9,10,1,70.00,0.00,70.00),
(1,10,19,1,110.00,0.00,110.00),
(2,10,21,1,200.00,0.00,200.00),
(1,11,2,1,160.00,0.00,160.00),
(2,11,18,1,240.00,0.00,240.00),
(3,11,8,1,95.00,0.00,95.00),
(1,12,24,1,150.00,0.00,150.00),
(2,12,23,1,130.00,0.00,130.00),
(3,12,6,1,90.00,20.00,70.00),
(1,13,3,1,170.00,0.00,170.00),
(2,13,20,1,190.00,0.00,190.00),
(3,13,7,1,100.00,10.00,90.00),
(1,14,5,1,180.00,0.00,180.00),
(2,14,17,1,180.00,0.00,180.00),
(3,14,12,1,220.00,0.00,220.00),
(1,15,13,1,260.00,0.00,260.00),
(2,15,11,1,140.00,0.00,140.00),
(3,15,8,1,95.00,0.00,95.00),
(1,16,22,1,230.00,0.00,230.00),
(2,16,19,1,110.00,0.00,110.00),
(1,17,21,1,200.00,0.00,200.00),
(2,17,15,1,210.00,0.00,210.00),
(1,18,18,1,240.00,0.00,240.00),
(2,18,4,1,190.00,0.00,190.00),
(3,18,6,1,90.00,0.00,90.00),
(1,19,2,1,160.00,0.00,160.00),
(2,19,5,1,180.00,0.00,180.00),
(3,19,13,1,260.00,0.00,260.00),
(1,20,4,1,190.00,0.00,190.00),
(2,20,18,1,240.00,0.00,240.00),
(3,20,19,1,110.00,0.00,110.00),
(1,21,3,1,170.00,0.00,170.00),
(2,21,12,1,220.00,0.00,220.00),
(3,21,7,1,100.00,0.00,100.00),
(1,22,2,1,160.00,0.00,160.00),
(2,22,13,1,260.00,0.00,260.00),
(3,22,11,1,140.00,0.00,140.00),
(1,23,1,1,120.00,0.00,120.00),
(2,23,17,1,180.00,0.00,180.00),
(3,23,10,1,70.00,0.00,70.00),
(1,24,5,1,180.00,0.00,180.00),
(2,24,20,1,190.00,0.00,190.00),
(3,24,14,1,150.00,10.00,140.00),
(1,25,12,1,220.00,0.00,220.00),
(2,25,19,1,110.00,0.00,110.00),
(3,25,9,1,80.00,0.00,80.00),
(1,26,2,1,160.00,0.00,160.00),
(2,26,18,1,240.00,0.00,240.00),
(3,26,6,1,90.00,0.00,90.00),
(1,27,15,1,210.00,0.00,210.00),
(2,27,22,1,230.00,0.00,230.00),
(3,27,10,1,70.00,0.00,70.00),
(1,28,3,1,170.00,0.00,170.00),
(2,28,5,1,180.00,0.00,180.00),
(3,28,8,1,95.00,0.00,95.00),
(1,29,13,1,260.00,0.00,260.00),
(2,29,17,1,180.00,0.00,180.00),
(3,29,19,1,110.00,0.00,110.00),
(1,30,21,1,200.00,0.00,200.00),
(2,30,24,1,150.00,0.00,150.00),
(1,31,4,1,190.00,0.00,190.00),
(2,31,12,1,220.00,0.00,220.00),
(3,31,11,1,140.00,0.00,140.00),
(1,32,18,1,240.00,0.00,240.00),
(2,32,13,1,260.00,0.00,260.00),
(3,32,6,1,90.00,30.00,60.00),
(1,33,2,1,160.00,0.00,160.00),
(2,33,20,1,190.00,0.00,190.00),
(3,33,9,1,80.00,0.00,80.00),
(1,34,1,1,120.00,0.00,120.00),
(2,34,14,1,150.00,0.00,150.00),
(3,34,10,1,70.00,0.00,70.00),
(1,35,5,1,180.00,0.00,180.00),
(2,35,18,1,240.00,0.00,240.00),
(3,35,7,1,100.00,0.00,100.00),
(1,36,12,1,220.00,0.00,220.00),
(2,36,23,1,130.00,0.00,130.00),
(3,36,9,1,80.00,0.00,80.00),
(1,37,13,1,260.00,0.00,260.00),
(2,37,4,1,190.00,0.00,190.00),
(3,37,19,1,110.00,0.00,110.00),
(1,38,22,1,230.00,0.00,230.00),
(2,38,15,1,210.00,0.00,210.00),
(3,38,10,1,70.00,0.00,70.00),
(1,39,18,1,240.00,0.00,240.00),
(2,39,20,1,190.00,0.00,190.00),
(3,39,8,1,95.00,0.00,95.00),
(1,40,3,1,170.00,0.00,170.00),
(2,40,12,1,220.00,0.00,220.00),
(3,40,14,1,150.00,0.00,150.00),
(1,41,5,1,180.00,0.00,180.00),
(2,41,13,1,260.00,0.00,260.00),
(3,41,19,1,110.00,0.00,110.00),
(1,42,4,1,190.00,0.00,190.00),
(2,42,17,1,180.00,0.00,180.00),
(3,42,10,1,70.00,0.00,70.00),
(1,43,21,1,200.00,0.00,200.00),
(2,43,22,1,230.00,0.00,230.00),
(3,43,6,1,90.00,0.00,90.00),
(1,44,2,1,160.00,0.00,160.00),
(2,44,18,1,240.00,0.00,240.00),
(3,44,9,1,80.00,0.00,80.00),
(1,45,12,1,220.00,0.00,220.00),
(2,45,3,1,170.00,0.00,170.00),
(3,45,19,1,110.00,0.00,110.00),
(1,46,13,1,260.00,0.00,260.00),
(2,46,5,1,180.00,0.00,180.00),
(3,46,7,1,100.00,0.00,100.00),
(1,47,4,1,190.00,0.00,190.00),
(2,47,17,1,180.00,0.00,180.00),
(3,47,10,1,70.00,0.00,70.00),
(1,49,15,1,210.00,0.00,210.00),
(2,49,22,1,230.00,0.00,230.00),
(3,49,9,1,80.00,0.00,80.00),
(1,50,18,1,240.00,0.00,240.00),
(2,50,12,1,220.00,0.00,220.00),
(3,50,10,1,70.00,0.00,70.00);

-- =========================
-- PAYMENTS
-- One payment for every order except the pending/cancelled examples.
-- =========================
INSERT INTO Payments
(order_id, payment_method, amount, payment_date, payment_status, transaction_id, notes)
VALUES
(1,'UPI',430.00,'2026-01-05 09:16:00','Paid','TXN0001',NULL),
(2,'Card',350.00,'2026-01-06 10:21:00','Paid','TXN0002',NULL),
(3,'Cash',320.00,'2026-01-10 13:06:00','Paid','TXN0003',NULL),
(4,'UPI',480.00,'2026-01-12 17:41:00','Paid','TXN0004',NULL),
(5,'Card',340.00,'2026-01-15 08:31:00','Paid','TXN0005',NULL),
(6,'UPI',430.00,'2026-02-02 09:46:00','Paid','TXN0006',NULL),
(7,'Wallet',490.00,'2026-02-05 11:11:00','Paid','TXN0007',NULL),
(8,'Card',450.00,'2026-02-08 14:26:00','Paid','TXN0008',NULL),
(9,'UPI',500.00,'2026-02-14 18:06:00','Paid','TXN0009',NULL),
(10,'Cash',310.00,'2026-02-18 16:36:00','Paid','TXN0010',NULL),
(11,'Card',475.00,'2026-02-22 12:16:00','Paid','TXN0011',NULL),
(12,'UPI',350.00,'2026-03-01 09:06:00','Paid','TXN0012',NULL),
(13,'Wallet',420.00,'2026-03-04 10:51:00','Paid','TXN0013',NULL),
(14,'Card',580.00,'2026-03-07 13:31:00','Paid','TXN0014',NULL),
(15,'UPI',455.00,'2026-03-10 19:21:00','Paid','TXN0015',NULL),
(16,'Cash',340.00,'2026-03-15 15:11:00','Paid','TXN0016',NULL),
(17,'Card',390.00,'2026-03-20 08:46:00','Paid','TXN0017',NULL),
(18,'UPI',520.00,'2026-03-25 12:41:00','Paid','TXN0018',NULL),
(19,'Card',580.00,'2026-04-02 10:06:00','Paid','TXN0019',NULL),
(20,'UPI',480.00,'2026-04-05 17:16:00','Paid','TXN0020',NULL),
(21,'Wallet',490.00,'2026-04-09 09:36:00','Paid','TXN0021',NULL),
(22,'Card',490.00,'2026-04-12 18:21:00','Paid','TXN0022',NULL),
(23,'Cash',370.00,'2026-04-18 13:51:00','Paid','TXN0023',NULL),
(24,'UPI',490.00,'2026-05-03 11:26:00','Paid','TXN0024',NULL),
(25,'Card',410.00,'2026-05-10 16:46:00','Paid','TXN0025',NULL),
(26,'UPI',450.00,'2026-05-18 19:11:00','Paid','TXN0026',NULL),
(27,'Card',470.00,'2026-06-01 09:26:00','Paid','TXN0027',NULL),
(28,'Cash',445.00,'2026-06-08 12:11:00','Paid','TXN0028',NULL),
(29,'UPI',500.00,'2026-06-15 17:56:00','Paid','TXN0029',NULL),
(30,'Wallet',350.00,'2026-06-22 14:06:00','Paid','TXN0030',NULL),
(31,'Card',540.00,'2026-07-02 10:16:00','Paid','TXN0031',NULL),
(32,'UPI',530.00,'2026-07-08 18:41:00','Paid','TXN0032',NULL),
(33,'Card',430.00,'2026-07-15 13:21:00','Paid','TXN0033',NULL),
(34,'Cash',340.00,'2026-07-22 09:56:00','Paid','TXN0034',NULL),
(35,'UPI',500.00,'2026-08-01 12:36:00','Paid','TXN0035',NULL),
(36,'Card',430.00,'2026-08-08 16:21:00','Paid','TXN0036',NULL),
(37,'UPI',480.00,'2026-08-15 18:06:00','Paid','TXN0037',NULL),
(38,'Wallet',510.00,'2026-08-22 10:31:00','Paid','TXN0038',NULL),
(39,'Card',515.00,'2026-08-28 14:46:00','Paid','TXN0039',NULL),
(40,'UPI',460.00,'2026-09-02 09:11:00','Paid','TXN0040',NULL),
(41,'Card',520.00,'2026-09-05 11:56:00','Paid','TXN0041',NULL),
(42,'UPI',420.00,'2026-09-10 17:26:00','Paid','TXN0042',NULL),
(43,'Cash',520.00,'2026-09-14 13:06:00','Paid','TXN0043',NULL),
(44,'Card',460.00,'2026-09-18 18:16:00','Paid','TXN0044',NULL),
(45,'UPI',440.00,'2026-09-20 09:41:00','Paid','TXN0045',NULL),
(46,'Card',530.00,'2026-09-22 15:31:00','Paid','TXN0046',NULL),
(47,'UPI',440.00,'2026-09-25 19:06:00','Pending','TXN0047','Payment awaiting confirmation'),
(48,'UPI',0.00,'2026-09-26 12:21:00','Failed','TXN0048','Order cancelled'),
(49,'Card',510.00,'2026-09-27 10:16:00','Paid','TXN0049',NULL),
(50,'UPI',510.00,'2026-09-28 11:21:00','Paid','TXN0050','Weekend cafe order');


-- ============================================================
-- FILE: Triggers/Cafe_Triggers.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 6: TRIGGERS
-- MySQL 8.0+
-- ============================================================

USE cafe_customer_analysis;

-- ============================================================
-- 6.1 Validate and calculate OrderItems before insert
-- ============================================================
DROP TRIGGER IF EXISTS trg_orderitems_before_insert;
DELIMITER $$

CREATE TRIGGER trg_orderitems_before_insert
BEFORE INSERT ON OrderItems
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_status VARCHAR(20);

    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order quantity must be greater than zero';
    END IF;

    IF NEW.discount_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order-item discount cannot be negative';
    END IF;

    SELECT price
      INTO v_price
      FROM Products
     WHERE product_id = NEW.product_id
       AND is_active = TRUE;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product does not exist or is inactive';
    END IF;

    SELECT order_status
      INTO v_status
      FROM Orders
     WHERE order_id = NEW.order_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order does not exist';
    END IF;

    IF v_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot add items to a cancelled order';
    END IF;

    SET NEW.unit_price = v_price;

    IF NEW.discount_amount > (v_price * NEW.quantity) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order-item discount cannot exceed line value';
    END IF;

    SET NEW.total_price =
        (v_price * NEW.quantity) - NEW.discount_amount;
END $$

DELIMITER ;

-- ============================================================
-- 6.2 Validate and recalculate OrderItems before update
-- ============================================================
DROP TRIGGER IF EXISTS trg_orderitems_before_update;
DELIMITER $$

CREATE TRIGGER trg_orderitems_before_update
BEFORE UPDATE ON OrderItems
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);

    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order quantity must be greater than zero';
    END IF;

    IF NEW.discount_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order-item discount cannot be negative';
    END IF;

    SELECT price
      INTO v_price
      FROM Products
     WHERE product_id = NEW.product_id
       AND is_active = TRUE;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product does not exist or is inactive';
    END IF;

    SET NEW.unit_price = v_price;

    IF NEW.discount_amount > (v_price * NEW.quantity) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order-item discount cannot exceed line value';
    END IF;

    SET NEW.total_price =
        (v_price * NEW.quantity) - NEW.discount_amount;
END $$

DELIMITER ;

-- ============================================================
-- 6.3 Recalculate order totals after inserting an item
-- ============================================================
DROP TRIGGER IF EXISTS trg_orderitems_after_insert;
DELIMITER $$

CREATE TRIGGER trg_orderitems_after_insert
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders o
       SET o.total_amount = (
               SELECT COALESCE(SUM(oi.total_price), 0)
                 FROM OrderItems oi
                WHERE oi.order_id = NEW.order_id
           ),
           o.final_amount = GREATEST(
               0,
               (
                   SELECT COALESCE(SUM(oi.total_price), 0)
                     FROM OrderItems oi
                    WHERE oi.order_id = NEW.order_id
               ) - o.discount_amount
           )
     WHERE o.order_id = NEW.order_id;
END $$

DELIMITER ;

-- ============================================================
-- 6.4 Recalculate order totals after updating an item
-- ============================================================
DROP TRIGGER IF EXISTS trg_orderitems_after_update;
DELIMITER $$

CREATE TRIGGER trg_orderitems_after_update
AFTER UPDATE ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders o
       SET o.total_amount = (
               SELECT COALESCE(SUM(oi.total_price), 0)
                 FROM OrderItems oi
                WHERE oi.order_id = NEW.order_id
           ),
           o.final_amount = GREATEST(
               0,
               (
                   SELECT COALESCE(SUM(oi.total_price), 0)
                     FROM OrderItems oi
                    WHERE oi.order_id = NEW.order_id
               ) - o.discount_amount
           )
     WHERE o.order_id = NEW.order_id;

    IF OLD.order_id <> NEW.order_id THEN
        UPDATE Orders o
           SET o.total_amount = (
                   SELECT COALESCE(SUM(oi.total_price), 0)
                     FROM OrderItems oi
                    WHERE oi.order_id = OLD.order_id
               ),
               o.final_amount = GREATEST(
                   0,
                   (
                       SELECT COALESCE(SUM(oi.total_price), 0)
                         FROM OrderItems oi
                        WHERE oi.order_id = OLD.order_id
                   ) - o.discount_amount
               )
         WHERE o.order_id = OLD.order_id;
    END IF;
END $$

DELIMITER ;

-- ============================================================
-- 6.5 Recalculate order totals after deleting an item
-- ============================================================
DROP TRIGGER IF EXISTS trg_orderitems_after_delete;
DELIMITER $$

CREATE TRIGGER trg_orderitems_after_delete
AFTER DELETE ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders o
       SET o.total_amount = (
               SELECT COALESCE(SUM(oi.total_price), 0)
                 FROM OrderItems oi
                WHERE oi.order_id = OLD.order_id
           ),
           o.final_amount = GREATEST(
               0,
               (
                   SELECT COALESCE(SUM(oi.total_price), 0)
                     FROM OrderItems oi
                    WHERE oi.order_id = OLD.order_id
               ) - o.discount_amount
           )
     WHERE o.order_id = OLD.order_id;
END $$

DELIMITER ;

-- ============================================================
-- 6.6 Audit product price changes
-- ============================================================
DROP TRIGGER IF EXISTS trg_products_price_audit;
DELIMITER $$

CREATE TRIGGER trg_products_price_audit
AFTER UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.price <> OLD.price THEN
        INSERT INTO ProductPriceAudit
            (product_id, old_price, new_price, changed_at)
        VALUES
            (NEW.product_id, OLD.price, NEW.price, NOW());
    END IF;
END $$

DELIMITER ;

-- ============================================================
-- 6.7 Audit order-status changes
-- ============================================================
DROP TRIGGER IF EXISTS trg_orders_status_audit;
DELIMITER $$

CREATE TRIGGER trg_orders_status_audit
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.order_status <> OLD.order_status THEN
        INSERT INTO OrderStatusAudit
            (order_id, old_status, new_status, changed_at)
        VALUES
            (NEW.order_id, OLD.order_status, NEW.order_status, NOW());
    END IF;
END $$

DELIMITER ;

-- ============================================================
-- 6.8 Prevent invalid order-level discount
-- ============================================================
DROP TRIGGER IF EXISTS trg_orders_before_insert;
DELIMITER $$

CREATE TRIGGER trg_orders_before_insert
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    IF NEW.discount_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order discount cannot be negative';
    END IF;

    IF NEW.discount_amount > NEW.total_amount AND NEW.total_amount > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order discount cannot exceed total amount';
    END IF;
END $$

DELIMITER ;

-- ============================================================
-- 6.9 Prevent invalid order-level discount updates
-- ============================================================
DROP TRIGGER IF EXISTS trg_orders_before_update;
DELIMITER $$

CREATE TRIGGER trg_orders_before_update
BEFORE UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.discount_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order discount cannot be negative';
    END IF;

    IF NEW.discount_amount > NEW.total_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order discount cannot exceed total amount';
    END IF;
END $$

DELIMITER ;


-- ============================================================
-- FILE: Views/Cafe_Analysis_Views.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 7: VIEWS
-- ============================================================

USE cafe_customer_analysis;

-- ============================================================
-- 7.1 Customer purchase summary
-- ============================================================
CREATE OR REPLACE VIEW vw_CustomerPurchaseSummary AS
SELECT
    c.customer_id,
    c.name AS customer_name,
    c.city,
    COUNT(DISTINCT CASE
        WHEN o.order_status <> 'Cancelled' THEN o.order_id
    END) AS total_orders,
    COALESCE(SUM(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN o.final_amount
            ELSE 0
        END
    ), 0) AS total_spending,
    COALESCE(AVG(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN o.final_amount
        END
    ), 0) AS average_order_value,
    MAX(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN o.order_date
        END
    ) AS last_order_date,
    c.loyalty_points
FROM Customers c
LEFT JOIN Orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.city,
    c.loyalty_points;

-- ============================================================
-- 7.2 Product sales summary
-- ============================================================
CREATE OR REPLACE VIEW vw_ProductSalesSummary AS
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.price AS current_price,
    p.is_active,
    COALESCE(SUM(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN oi.quantity
            ELSE 0
        END
    ), 0) AS quantity_sold,
    COALESCE(SUM(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN oi.total_price
            ELSE 0
        END
    ), 0) AS revenue,
    COUNT(DISTINCT CASE
        WHEN o.order_status <> 'Cancelled' THEN o.order_id
    END) AS number_of_orders
FROM Products p
JOIN Categories c
    ON p.category_id = c.category_id
LEFT JOIN OrderItems oi
    ON p.product_id = oi.product_id
LEFT JOIN Orders o
    ON oi.order_id = o.order_id
GROUP BY
    p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    p.is_active;

-- ============================================================
-- 7.3 Order details
-- ============================================================
CREATE OR REPLACE VIEW vw_OrderDetails AS
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.name AS customer_name,
    e.employee_id,
    e.name AS employee_name,
    o.order_status,
    o.total_amount,
    o.discount_amount,
    o.final_amount,
    p.payment_method,
    p.payment_status,
    p.amount AS payment_amount
FROM Orders o
JOIN Customers c
    ON o.customer_id = c.customer_id
JOIN Employees e
    ON o.employee_id = e.employee_id
LEFT JOIN Payments p
    ON o.order_id = p.order_id;

-- ============================================================
-- 7.4 Category revenue summary
-- ============================================================
CREATE OR REPLACE VIEW vw_CategoryRevenue AS
SELECT
    c.category_id,
    c.category_name,
    COUNT(DISTINCT CASE
        WHEN o.order_status <> 'Cancelled' THEN o.order_id
    END) AS order_count,
    COALESCE(SUM(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN oi.quantity
            ELSE 0
        END
    ), 0) AS quantity_sold,
    COALESCE(SUM(
        CASE
            WHEN o.order_status <> 'Cancelled' THEN oi.total_price
            ELSE 0
        END
    ), 0) AS revenue
FROM Categories c
LEFT JOIN Products p
    ON c.category_id = p.category_id
LEFT JOIN OrderItems oi
    ON p.product_id = oi.product_id
LEFT JOIN Orders o
    ON oi.order_id = o.order_id
GROUP BY
    c.category_id,
    c.category_name;

-- ============================================================
-- 7.5 Payment summary
-- ============================================================
CREATE OR REPLACE VIEW vw_PaymentSummary AS
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) AS paid_amount,
    SUM(CASE WHEN payment_status = 'Pending' THEN amount ELSE 0 END) AS pending_amount,
    SUM(CASE WHEN payment_status = 'Failed' THEN amount ELSE 0 END) AS failed_amount,
    SUM(CASE WHEN payment_status = 'Refunded' THEN amount ELSE 0 END) AS refunded_amount
FROM Payments
GROUP BY payment_method;

-- ============================================================
-- 7.6 Order item details
-- ============================================================
CREATE OR REPLACE VIEW vw_OrderItemDetails AS
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.line_no,
    p.product_id,
    p.product_name,
    c.category_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    oi.total_price,
    o.order_date,
    o.order_status
FROM OrderItems oi
JOIN Products p
    ON oi.product_id = p.product_id
JOIN Categories c
    ON p.category_id = c.category_id
JOIN Orders o
    ON oi.order_id = o.order_id;

-- ============================================================
-- 7.7 Active products with sales status
-- ============================================================
CREATE OR REPLACE VIEW vw_ProductPerformance AS
SELECT
    ps.product_id,
    ps.product_name,
    ps.category_name,
    ps.quantity_sold,
    ps.revenue,
    CASE
        WHEN ps.quantity_sold = 0 THEN 'No Sales'
        WHEN ps.quantity_sold < 5 THEN 'Low Sales'
        WHEN ps.quantity_sold < 10 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_segment
FROM vw_ProductSalesSummary ps
WHERE ps.is_active = TRUE;


-- ============================================================
-- FILE: Stored_Procedures/Cafe_Stored_Procedures.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PART 8: STORED PROCEDURES
-- MySQL 8.0+
-- ============================================================

USE cafe_customer_analysis;

-- ============================================================
-- 8.1 Customer purchase history
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetCustomerPurchaseHistory;
DELIMITER $$

CREATE PROCEDURE sp_GetCustomerPurchaseHistory(
    IN p_customer_id INT
)
BEGIN
    SELECT
        o.order_id,
        o.order_date,
        o.order_status,
        o.total_amount,
        o.discount_amount,
        o.final_amount,
        p.payment_method,
        p.payment_status
    FROM Orders o
    LEFT JOIN Payments p
        ON o.order_id = p.order_id
    WHERE o.customer_id = p_customer_id
    ORDER BY o.order_date;
END $$

DELIMITER ;

-- ============================================================
-- 8.2 Sales by date range
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetSalesByDateRange;
DELIMITER $$

CREATE PROCEDURE sp_GetSalesByDateRange(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    IF p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Start date cannot be after end date';
    END IF;

    SELECT
        DATE(o.order_date) AS sales_date,
        COUNT(DISTINCT o.order_id) AS order_count,
        COALESCE(SUM(o.final_amount), 0) AS revenue
    FROM Orders o
    WHERE o.order_date >= p_start_date
      AND o.order_date < DATE_ADD(p_end_date, INTERVAL 1 DAY)
      AND o.order_status <> 'Cancelled'
    GROUP BY DATE(o.order_date)
    ORDER BY sales_date;
END $$

DELIMITER ;

-- ============================================================
-- 8.3 Top N customers
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetTopCustomers;
DELIMITER $$

CREATE PROCEDURE sp_GetTopCustomers(
    IN p_top_n INT
)
BEGIN
    IF p_top_n <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Top N must be greater than zero';
    END IF;

    SELECT
        customer_id,
        customer_name,
        total_orders,
        total_spending,
        average_order_value,
        last_order_date
    FROM vw_CustomerPurchaseSummary
    ORDER BY total_spending DESC
    LIMIT p_top_n;
END $$

DELIMITER ;

-- ============================================================
-- 8.4 Product sales
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetProductSales;
DELIMITER $$

CREATE PROCEDURE sp_GetProductSales(
    IN p_product_id INT
)
BEGIN
    SELECT
        product_id,
        product_name,
        category_name,
        current_price,
        quantity_sold,
        revenue,
        number_of_orders
    FROM vw_ProductSalesSummary
    WHERE product_id = p_product_id;
END $$

DELIMITER ;

-- ============================================================
-- 8.5 Revenue by payment method
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetRevenueByPaymentMethod;
DELIMITER $$

CREATE PROCEDURE sp_GetRevenueByPaymentMethod()
BEGIN
    SELECT
        payment_method,
        payment_count,
        paid_amount,
        pending_amount,
        failed_amount,
        refunded_amount
    FROM vw_PaymentSummary
    ORDER BY paid_amount DESC;
END $$

DELIMITER ;

-- ============================================================
-- 8.6 Monthly revenue
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetMonthlyRevenue;
DELIMITER $$

CREATE PROCEDURE sp_GetMonthlyRevenue()
BEGIN
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS revenue_month,
        COUNT(*) AS order_count,
        SUM(final_amount) AS revenue
    FROM Orders
    WHERE order_status <> 'Cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
    ORDER BY revenue_month;
END $$

DELIMITER ;

-- ============================================================
-- 8.7 Customer order frequency
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GetCustomerOrderFrequency;
DELIMITER $$

CREATE PROCEDURE sp_GetCustomerOrderFrequency()
BEGIN
    SELECT
        customer_id,
        customer_name,
        total_orders,
        total_spending,
        CASE
            WHEN total_orders = 0 THEN 'No Orders'
            WHEN total_orders = 1 THEN 'One-Time'
            WHEN total_orders BETWEEN 2 AND 4 THEN 'Repeat'
            ELSE 'Frequent'
        END AS customer_segment
    FROM vw_CustomerPurchaseSummary
    ORDER BY total_orders DESC, total_spending DESC;
END $$

DELIMITER ;


-- ============================================================
-- FILE: Analysis/01_Customer_Analysis.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- CUSTOMER ANALYSIS
-- ============================================================

USE cafe_customer_analysis;

-- Q1. Total customers
SELECT COUNT(*) AS total_customers
FROM Customers;

-- Q2. Customer order frequency
SELECT
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS total_orders
FROM Customers c
LEFT JOIN Orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_orders DESC;

-- Q3. Customer lifetime spending
SELECT
    c.customer_id,
    c.name,
    COALESCE(SUM(
        CASE WHEN o.order_status <> 'Cancelled'
             THEN o.final_amount ELSE 0 END
    ), 0) AS lifetime_spending
FROM Customers c
LEFT JOIN Orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY lifetime_spending DESC;

-- Q4. Average customer spending
SELECT
    AVG(total_spending) AS average_customer_spending
FROM vw_CustomerPurchaseSummary;

-- Q5. Repeat customers
SELECT
    customer_id,
    customer_name,
    total_orders
FROM vw_CustomerPurchaseSummary
WHERE total_orders >= 2
ORDER BY total_orders DESC;

-- Q6. Customers with no orders
SELECT
    c.customer_id,
    c.name,
    c.city
FROM Customers c
LEFT JOIN Orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Q7. Inactive customers
SELECT
    customer_id,
    name,
    city,
    join_date
FROM Customers
WHERE is_active = FALSE;

-- Q8. Top 10 customers by spending
SELECT
    customer_id,
    customer_name,
    total_spending
FROM vw_CustomerPurchaseSummary
ORDER BY total_spending DESC
LIMIT 10;

-- Q9. Customer segmentation using CASE
SELECT
    customer_id,
    customer_name,
    total_orders,
    total_spending,
    CASE
        WHEN total_spending = 0 THEN 'No Purchase'
        WHEN total_spending < 500 THEN 'Low Value'
        WHEN total_spending < 1000 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_segment
FROM vw_CustomerPurchaseSummary
ORDER BY total_spending DESC;

-- Q10. Customers spending above the average customer spending
WITH customer_spending AS (
    SELECT customer_id, customer_name, total_spending
    FROM vw_CustomerPurchaseSummary
)
SELECT *
FROM customer_spending
WHERE total_spending > (
    SELECT AVG(total_spending)
    FROM customer_spending
)
ORDER BY total_spending DESC;

-- Q11. Customers who purchased from at least 3 different categories
SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT p.category_id) AS categories_purchased
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
JOIN OrderItems oi
    ON o.order_id = oi.order_id
JOIN Products p
    ON oi.product_id = p.product_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT p.category_id) >= 3
ORDER BY categories_purchased DESC;

-- Q12. Most recent order for every customer
WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.final_amount,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC
        ) AS rn
    FROM Orders o
    WHERE o.order_status <> 'Cancelled'
)
SELECT
    c.customer_id,
    c.name,
    r.order_id,
    r.order_date,
    r.final_amount
FROM Customers c
LEFT JOIN ranked_orders r
    ON c.customer_id = r.customer_id
   AND r.rn = 1
ORDER BY r.order_date DESC;


-- ============================================================
-- FILE: Analysis/02_Product_Analysis.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- PRODUCT ANALYSIS
-- ============================================================

USE cafe_customer_analysis;

-- Q13. Best-selling products by quantity
SELECT
    product_id,
    product_name,
    quantity_sold
FROM vw_ProductSalesSummary
ORDER BY quantity_sold DESC, product_name
LIMIT 10;

-- Q14. Highest-revenue products
SELECT
    product_id,
    product_name,
    revenue
FROM vw_ProductSalesSummary
ORDER BY revenue DESC
LIMIT 10;

-- Q15. Products with no orders
SELECT
    product_id,
    product_name,
    category_name
FROM vw_ProductSalesSummary
WHERE quantity_sold = 0;

-- Q16. Low-performing products
SELECT
    product_id,
    product_name,
    category_name,
    quantity_sold,
    revenue
FROM vw_ProductPerformance
WHERE sales_segment IN ('No Sales', 'Low Sales')
ORDER BY quantity_sold, revenue;

-- Q17. Revenue by category
SELECT
    category_id,
    category_name,
    quantity_sold,
    revenue
FROM vw_CategoryRevenue
ORDER BY revenue DESC;

-- Q18. Average selling price by category
SELECT
    c.category_id,
    c.category_name,
    ROUND(AVG(p.price), 2) AS average_product_price
FROM Categories c
JOIN Products p
    ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY average_product_price DESC;

-- Q19. Product contribution to total revenue
SELECT
    product_id,
    product_name,
    revenue,
    ROUND(
        100 * revenue / NULLIF(
            (SELECT SUM(revenue)
             FROM vw_ProductSalesSummary),
            0
        ), 2
    ) AS revenue_percentage
FROM vw_ProductSalesSummary
ORDER BY revenue_percentage DESC;

-- Q20. Rank products by revenue
SELECT
    product_id,
    product_name,
    category_name,
    revenue,
    DENSE_RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank
FROM vw_ProductSalesSummary
ORDER BY revenue_rank;

-- Q21. Top 3 products within each category
WITH ranked_products AS (
    SELECT
        product_id,
        product_name,
        category_name,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY revenue DESC
        ) AS category_rank
    FROM vw_ProductSalesSummary
)
SELECT *
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category_name, category_rank;

-- Q22. Estimated product profit
SELECT
    p.product_id,
    p.product_name,
    p.price AS selling_price,
    -- This project does not store product cost_price in the ER schema.
    -- Therefore this query reports sales revenue, not profit.
    ps.quantity_sold,
    ps.revenue
FROM Products p
JOIN vw_ProductSalesSummary ps
    ON p.product_id = ps.product_id
ORDER BY ps.revenue DESC;


-- ============================================================
-- FILE: Analysis/03_Order_Analysis.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- ORDER ANALYSIS
-- ============================================================

USE cafe_customer_analysis;

-- Q23. Total orders
SELECT COUNT(*) AS total_orders
FROM Orders;

-- Q24. Average Order Value
SELECT
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM Orders
WHERE order_status <> 'Cancelled';

-- Q25. Daily order volume
SELECT
    DATE(order_date) AS order_day,
    COUNT(*) AS order_count
FROM Orders
GROUP BY DATE(order_date)
ORDER BY order_day;

-- Q26. Monthly order trends
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(*) AS order_count,
    SUM(final_amount) AS revenue
FROM Orders
WHERE order_status <> 'Cancelled'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- Q27. Busy ordering hours
SELECT
    HOUR(order_date) AS order_hour,
    COUNT(*) AS order_count
FROM Orders
GROUP BY HOUR(order_date)
ORDER BY order_count DESC;

-- Q28. Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100 * COUNT(*) / (SELECT COUNT(*) FROM Orders),
        2
    ) AS percentage_of_orders
FROM Orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Q29. Orders above the average order value
SELECT
    order_id,
    customer_id,
    order_date,
    final_amount
FROM Orders
WHERE order_status <> 'Cancelled'
  AND final_amount > (
      SELECT AVG(final_amount)
      FROM Orders
      WHERE order_status <> 'Cancelled'
  )
ORDER BY final_amount DESC;

-- Q30. Orders with multiple items
SELECT
    o.order_id,
    c.name AS customer_name,
    COUNT(oi.order_item_id) AS item_lines,
    SUM(oi.quantity) AS total_quantity,
    o.final_amount
FROM Orders o
JOIN Customers c
    ON o.customer_id = c.customer_id
JOIN OrderItems oi
    ON o.order_id = oi.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY
    o.order_id,
    c.name,
    o.final_amount
HAVING COUNT(oi.order_item_id) > 1
ORDER BY item_lines DESC;

-- Q31. Orders handled by each employee
SELECT
    e.employee_id,
    e.name AS employee_name,
    COUNT(o.order_id) AS orders_handled,
    COALESCE(SUM(
        CASE WHEN o.order_status <> 'Cancelled'
             THEN o.final_amount ELSE 0 END
    ), 0) AS handled_revenue
FROM Employees e
LEFT JOIN Orders o
    ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.name
ORDER BY orders_handled DESC;

-- Q32. Average order value by employee
SELECT
    e.employee_id,
    e.name AS employee_name,
    ROUND(
        AVG(
            CASE WHEN o.order_status <> 'Cancelled'
                 THEN o.final_amount END
        ), 2
    ) AS average_order_value
FROM Employees e
LEFT JOIN Orders o
    ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.name
ORDER BY average_order_value DESC;


-- ============================================================
-- FILE: Analysis/04_Revenue_Analysis.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- REVENUE AND PAYMENT ANALYSIS
-- ============================================================

USE cafe_customer_analysis;

-- Q33. Total revenue
SELECT
    ROUND(SUM(final_amount), 2) AS total_revenue
FROM Orders
WHERE order_status <> 'Cancelled';

-- Q34. Monthly revenue
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS revenue_month,
    ROUND(SUM(final_amount), 2) AS monthly_revenue
FROM Orders
WHERE order_status <> 'Cancelled'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY revenue_month;

-- Q35. Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    ROUND(
        SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END),
        2
    ) AS paid_revenue
FROM Payments
GROUP BY payment_method
ORDER BY paid_revenue DESC;

-- Q36. Payment status analysis
SELECT
    payment_status,
    COUNT(*) AS payment_count,
    ROUND(SUM(amount), 2) AS payment_amount
FROM Payments
GROUP BY payment_status
ORDER BY payment_amount DESC;

-- Q37. Top revenue-generating customers
SELECT
    c.customer_id,
    c.name,
    ROUND(SUM(o.final_amount), 2) AS revenue
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.name
ORDER BY revenue DESC
LIMIT 10;

-- Q38. Revenue percentage by category
WITH category_revenue AS (
    SELECT
        category_name,
        revenue
    FROM vw_CategoryRevenue
)
SELECT
    category_name,
    revenue,
    ROUND(
        100 * revenue /
        NULLIF((SELECT SUM(revenue) FROM category_revenue), 0),
        2
    ) AS revenue_percentage
FROM category_revenue
ORDER BY revenue_percentage DESC;

-- Q39. Month-over-month revenue growth
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS revenue_month,
        SUM(final_amount) AS revenue
    FROM Orders
    WHERE order_status <> 'Cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
revenue_with_previous AS (
    SELECT
        revenue_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    revenue,
    previous_month_revenue,
    ROUND(
        100 * (revenue - previous_month_revenue) /
        NULLIF(previous_month_revenue, 0),
        2
    ) AS growth_percentage
FROM revenue_with_previous
ORDER BY revenue_month;

-- Q40. Cumulative revenue
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS revenue_month,
        SUM(final_amount) AS revenue
    FROM Orders
    WHERE order_status <> 'Cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    revenue_month,
    revenue,
    SUM(revenue) OVER (
        ORDER BY revenue_month
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY revenue_month;

-- Q41. Payment amount vs order final amount
SELECT
    o.order_id,
    o.final_amount AS order_final_amount,
    p.amount AS payment_amount,
    p.payment_status,
    CASE
        WHEN p.payment_status = 'Paid'
             AND p.amount = o.final_amount THEN 'Matched'
        WHEN p.payment_status = 'Paid'
             AND p.amount <> o.final_amount THEN 'Mismatch'
        WHEN p.payment_status IN ('Pending','Failed') THEN 'Unsettled'
        ELSE 'Review'
    END AS payment_check
FROM Orders o
LEFT JOIN Payments p
    ON o.order_id = p.order_id
ORDER BY o.order_id;

-- Q42. Revenue by city
SELECT
    c.city,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(o.final_amount), 2) AS revenue
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.city
ORDER BY revenue DESC;


-- ============================================================
-- FILE: Analysis/05_Advanced_Analysis.sql
-- ============================================================
-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- ADVANCED ANALYSIS
-- ============================================================

USE cafe_customer_analysis;

-- Q43. First order for each customer
WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.final_amount,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM Orders o
    WHERE o.order_status <> 'Cancelled'
)
SELECT
    c.customer_id,
    c.name,
    r.order_id AS first_order_id,
    r.order_date AS first_order_date,
    r.final_amount AS first_order_value
FROM Customers c
JOIN ranked_orders r
    ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY first_order_date;

-- Q44. Second order for each customer where available
WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM Orders o
    WHERE o.order_status <> 'Cancelled'
)
SELECT
    c.customer_id,
    c.name,
    r.order_id AS second_order_id,
    r.order_date AS second_order_date
FROM Customers c
JOIN ranked_orders r
    ON c.customer_id = r.customer_id
WHERE r.rn = 2
ORDER BY second_order_date;

-- Q45. Repeat-customer percentage
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders
    FROM Orders
    WHERE order_status <> 'Cancelled'
    GROUP BY customer_id
)
SELECT
    ROUND(
        100 * SUM(CASE WHEN total_orders >= 2 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;

-- Q46. Customer rank by spending
SELECT
    customer_id,
    customer_name,
    total_spending,
    RANK() OVER (
        ORDER BY total_spending DESC
    ) AS spending_rank
FROM vw_CustomerPurchaseSummary
ORDER BY spending_rank;

-- Q47. Running revenue by order date
SELECT
    order_id,
    order_date,
    final_amount,
    SUM(final_amount) OVER (
        ORDER BY order_date, order_id
    ) AS running_revenue
FROM Orders
WHERE order_status <> 'Cancelled'
ORDER BY order_date, order_id;

-- Q48. Category ranking by revenue
SELECT
    category_name,
    revenue,
    DENSE_RANK() OVER (
        ORDER BY revenue DESC
    ) AS category_rank
FROM vw_CategoryRevenue
ORDER BY category_rank;

-- Q49. Customers with no order in the latest 60 days of the dataset
WITH max_order_date AS (
    SELECT MAX(order_date) AS max_date
    FROM Orders
    WHERE order_status <> 'Cancelled'
)
SELECT
    c.customer_id,
    c.name,
    MAX(o.order_date) AS last_order_date
FROM Customers c
LEFT JOIN Orders o
    ON c.customer_id = o.customer_id
   AND o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.name
HAVING
    MAX(o.order_date) IS NULL
    OR MAX(o.order_date) < (
        SELECT DATE_SUB(max_date, INTERVAL 60 DAY)
        FROM max_order_date
    )
ORDER BY last_order_date;

-- Q50. Customers whose latest order value is above their own average
WITH customer_order_stats AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.final_amount,
        AVG(o.final_amount) OVER (
            PARTITION BY o.customer_id
        ) AS customer_avg_order_value,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC, o.order_id DESC
        ) AS rn
    FROM Orders o
    WHERE o.order_status <> 'Cancelled'
)
SELECT
    c.customer_id,
    c.name,
    s.order_id AS latest_order_id,
    s.final_amount AS latest_order_value,
    ROUND(s.customer_avg_order_value, 2) AS customer_average_order_value
FROM customer_order_stats s
JOIN Customers c
    ON c.customer_id = s.customer_id
WHERE s.rn = 1
  AND s.final_amount > s.customer_avg_order_value
ORDER BY s.final_amount DESC;

-- Q51. Products contributing at least 10% of total product revenue
SELECT
    product_id,
    product_name,
    revenue,
    ROUND(
        100 * revenue /
        NULLIF(
            (SELECT SUM(revenue)
             FROM vw_ProductSalesSummary),
            0
        ),
        2
    ) AS revenue_percentage
FROM vw_ProductSalesSummary
WHERE revenue >= 0.10 * (
    SELECT SUM(revenue)
    FROM vw_ProductSalesSummary
)
ORDER BY revenue DESC;

-- Q52. Employee revenue contribution
WITH employee_revenue AS (
    SELECT
        e.employee_id,
        e.name AS employee_name,
        COALESCE(SUM(
            CASE WHEN o.order_status <> 'Cancelled'
                 THEN o.final_amount ELSE 0 END
        ), 0) AS revenue
    FROM Employees e
    LEFT JOIN Orders o
        ON e.employee_id = o.employee_id
    GROUP BY e.employee_id, e.name
)
SELECT
    employee_id,
    employee_name,
    revenue,
    ROUND(
        100 * revenue /
        NULLIF((SELECT SUM(revenue) FROM employee_revenue), 0),
        2
    ) AS revenue_percentage
FROM employee_revenue
ORDER BY revenue DESC;

-- Q53. Product sales by month
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    p.product_name,
    SUM(oi.quantity) AS quantity_sold,
    SUM(oi.total_price) AS revenue
FROM Orders o
JOIN OrderItems oi
    ON o.order_id = oi.order_id
JOIN Products p
    ON oi.product_id = p.product_id
WHERE o.order_status <> 'Cancelled'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.product_name
ORDER BY sales_month, revenue DESC;

-- Q54. Category performance with average order contribution
SELECT
    c.category_name,
    SUM(oi.total_price) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders_containing_category,
    ROUND(
        SUM(oi.total_price) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_category_revenue_per_order
FROM Categories c
JOIN Products p
    ON c.category_id = p.category_id
JOIN OrderItems oi
    ON p.product_id = oi.product_id
JOIN Orders o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC;

-- Q55. Order status and payment status combination
SELECT
    o.order_status,
    COALESCE(p.payment_status, 'No Payment') AS payment_status,
    COUNT(*) AS order_count
FROM Orders o
LEFT JOIN Payments p
    ON o.order_id = p.order_id
GROUP BY
    o.order_status,
    COALESCE(p.payment_status, 'No Payment')
ORDER BY order_count DESC;

-- Q56. Verify stored order totals against order-item totals
SELECT
    o.order_id,
    o.total_amount AS stored_total,
    COALESCE(SUM(oi.total_price), 0) AS calculated_total,
    o.final_amount AS stored_final_amount,
    ROUND(
        COALESCE(SUM(oi.total_price), 0) - o.total_amount,
        2
    ) AS total_difference
FROM Orders o
LEFT JOIN OrderItems oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.total_amount,
    o.final_amount
HAVING
    ROUND(COALESCE(SUM(oi.total_price), 0) - o.total_amount, 2) <> 0
ORDER BY o.order_id;
