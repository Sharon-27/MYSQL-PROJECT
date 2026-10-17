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
