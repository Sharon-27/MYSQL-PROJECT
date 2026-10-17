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
