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

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.2 Validate and recalculate OrderItems before update
-- ============================================================

DROP TRIGGER IF EXISTS trg_orderitems_before_update;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.3 Recalculate order totals after inserting an item
-- ============================================================

DROP TRIGGER IF EXISTS trg_orderitems_after_insert;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.4 Recalculate order totals after updating an item
-- ============================================================

DROP TRIGGER IF EXISTS trg_orderitems_after_update;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.5 Recalculate order totals after deleting an item
-- ============================================================

DROP TRIGGER IF EXISTS trg_orderitems_after_delete;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.6 Audit product price changes
-- ============================================================

DROP TRIGGER IF EXISTS trg_products_price_audit;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.7 Audit order-status changes
-- ============================================================

DROP TRIGGER IF EXISTS trg_orders_status_audit;

DELIMITER //

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

END //

DELIMITER ;


-- ============================================================
-- 6.8 Prevent invalid order-level discount
-- ============================================================

DROP TRIGGER IF EXISTS trg_orders_before_insert;

DELIMITER //

CREATE TRIGGER trg_orders_before_insert
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN

    IF NEW.discount_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order discount cannot be negative';
    END IF;

    IF NEW.discount_amount > NEW.total_amount
       AND NEW.total_amount > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order discount cannot exceed total amount';

    END IF;

END //

DELIMITER ;


-- ============================================================
-- 6.9 Prevent invalid order-level discount updates
-- ============================================================

DROP TRIGGER IF EXISTS trg_orders_before_update;

DELIMITER //

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

END //

DELIMITER ;