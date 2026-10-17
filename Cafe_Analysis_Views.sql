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
