# Business Requirements

## Business Goal

The cafe needs a relational database that stores customer, menu, employee, order,
order-item, and payment information and supports business analysis.

## Questions to Answer

1. Who are the highest-value customers?
2. Which products sell most frequently?
3. Which products generate the most revenue?
4. Which categories perform best?
5. What is the average order value?
6. Which customers are repeat customers?
7. Which customers have no orders?
8. Which products have no sales?
9. What are the busiest ordering hours?
10. How does revenue change over time?
11. Which payment method is used most frequently?
12. What percentage of revenue comes from each category?
13. Which employees handle the most orders?
14. Which customers purchase across multiple categories?

## Database Requirements

- Seven core business tables.
- Primary keys for entity identification.
- Foreign keys for relationships.
- Unique constraints where appropriate.
- CHECK constraints for non-negative monetary values and valid quantities.
- Indexes for common joins and filters.
- Views for reusable analytical reporting.
- Stored procedures for parameterized operations.
- Triggers for validation, calculation, and auditing.
