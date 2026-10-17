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
