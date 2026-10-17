-- ============================================================
-- CAFE CUSTOMER ANALYSIS
-- DEMO COMMANDS
-- ============================================================
USE cafe_customer_analysis;

-- -------------------------
-- View demos
-- -------------------------
SELECT * FROM vw_CustomerPurchaseSummary;
SELECT * FROM vw_ProductSalesSummary;
SELECT * FROM vw_OrderDetails;
SELECT * FROM vw_CategoryRevenue;
SELECT * FROM vw_PaymentSummary;
SELECT * FROM vw_OrderItemDetails;
SELECT * FROM vw_ProductPerformance;

-- -------------------------
-- Stored procedure demos
-- -------------------------
CALL sp_GetCustomerPurchaseHistory(1);
CALL sp_GetSalesByDateRange('2026-01-01', '2026-03-31');
CALL sp_GetTopCustomers(10);
CALL sp_GetProductSales(2);
CALL sp_GetRevenueByPaymentMethod();
CALL sp_GetMonthlyRevenue();
CALL sp_GetCustomerOrderFrequency();

-- -------------------------
-- Trigger audit demos
-- -------------------------
-- Change a product price and then inspect ProductPriceAudit.
-- UPDATE Products SET price = price + 5 WHERE product_id = 1;
-- SELECT * FROM ProductPriceAudit ORDER BY audit_id DESC;

-- Change an order status and then inspect OrderStatusAudit.
-- UPDATE Orders SET order_status = 'Refunded' WHERE order_id = 47;
-- SELECT * FROM OrderStatusAudit ORDER BY audit_id DESC;

-- Insert a new order item to see automatic price/total calculation.
-- INSERT INTO OrderItems
-- (line_no, order_id, product_id, quantity, unit_price, discount_amount, total_price)
-- VALUES (4, 1, 1, 2, 0, 0, 0);
-- SELECT * FROM OrderItems WHERE order_id = 1 ORDER BY line_no;
-- SELECT order_id, total_amount, discount_amount, final_amount
-- FROM Orders WHERE order_id = 1;
