# Data Dictionary

## Categories
- `category_id`: Primary key.
- `category_name`: Unique category name.
- `description`: Category description.

## Employees
- `employee_id`: Primary key.
- `name`: Employee name.
- `role`: Job role.
- `phone`: Contact number.
- `hire_date`: Date employee joined.
- `is_active`: Employee availability flag.

## Customers
- `customer_id`: Primary key.
- `name`: Customer name.
- `email`: Unique email.
- `phone`: Unique phone.
- `date_of_birth`: Customer birth date.
- `gender`: Gender value.
- `join_date`: Customer registration date.
- `is_active`: Customer activity flag.
- `loyalty_points`: Accumulated loyalty points.
- `city`: Customer city.

## Products
- `product_id`: Primary key.
- `product_name`: Menu item name.
- `price`: Current selling price.
- `description`: Product description.
- `is_active`: Whether product can be sold.
- `category_id`: Foreign key to Categories.

## Orders
- `order_id`: Primary key.
- `customer_id`: Foreign key to Customers.
- `employee_id`: Foreign key to Employees.
- `order_date`: Date and time of order.
- `order_status`: Pending, Completed, Cancelled, or Refunded.
- `total_amount`: Sum of order-item totals before order-level discount.
- `discount_amount`: Order-level discount.
- `final_amount`: Amount after order-level discount.
- `notes`: Optional order notes.

## OrderItems
- `order_item_id`: Primary key.
- `line_no`: Line number within an order.
- `order_id`: Foreign key to Orders.
- `product_id`: Foreign key to Products.
- `quantity`: Quantity ordered.
- `unit_price`: Product price captured for the transaction.
- `discount_amount`: Discount applied to the line.
- `total_price`: Final line amount.

## Payments
- `payment_id`: Primary key.
- `order_id`: Unique foreign key to Orders.
- `payment_method`: Cash, Card, UPI, or Wallet.
- `amount`: Payment amount.
- `payment_date`: Payment timestamp.
- `payment_status`: Pending, Paid, Failed, or Refunded.
- `transaction_id`: Payment reference.
- `notes`: Optional payment notes.

## ProductPriceAudit
Stores product price changes.

- `audit_id`: Unique audit ID.
- `product_id`: Product whose price changed.
- `old_price`: Previous price.
- `new_price`: New price.
- `changed_at`: Date and time of the change.

## OrderStatusAudit
Stores order-status changes.

- `audit_id`: Unique audit ID.
- `order_id`: Order whose status changed.
- `old_status`: Previous order status.
- `new_status`: New order status.
- `changed_at`: Date and time of the change.
