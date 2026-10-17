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
