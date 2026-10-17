# Query Explanations

## Customer Analysis

Customer analysis uses `Customers` and `Orders` to measure order frequency,
lifetime spending, repeat behavior, inactive customers, and segmentation.

## Product Analysis

Product analysis joins `Products`, `Categories`, `OrderItems`, and `Orders`.
It measures quantity sold, revenue, category performance, and product ranking.

## Order Analysis

Order analysis focuses on `Orders` and uses date/time functions such as `DATE()`,
`DATE_FORMAT()`, and `HOUR()` to identify daily, monthly, and hourly patterns.

## Revenue and Payment Analysis

Revenue analysis uses `final_amount` for valid orders and joins payment data to
understand payment methods and payment status.

## Advanced Analysis

The advanced queries demonstrate:
- CTEs
- `RANK()`
- `DENSE_RANK()`
- `ROW_NUMBER()`
- `LAG()`
- `SUM() OVER()`
- conditional aggregation
- percentage calculations
- multi-table analytical joins

## Important Business Rule

Cancelled orders are excluded from most revenue and customer-spending calculations.

## Trigger Logic

Order-item triggers validate quantities and calculate transaction line totals.
After insert/update/delete operations, the order total is recalculated.

Product price changes and order-status changes are recorded in audit tables.
