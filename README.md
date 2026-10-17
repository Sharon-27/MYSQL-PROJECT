# ☕ Cafe Customer Analysis

MySQL portfolio project focused on understanding customer behavior, product performance, order patterns, payments, and cafe revenue using relational database design and analytical SQL.

---

## 1. Project Overview

**Cafe Customer Analysis** is an end-to-end MySQL data analysis project built around a fictional cafe business.

The project starts from business requirements and database design, then moves through data creation, data validation, business analysis, reusable database objects, and documentation.

The goal is to demonstrate practical SQL skills rather than only isolated SQL syntax.

### Main areas of analysis

- Customer purchasing behavior
- Customer value and repeat purchases
- Product and category performance
- Order trends and order value
- Revenue and payment analysis
- Operational patterns such as busy ordering periods

---

## 2. Business Problem

A cafe generates customer, order, product, employee, and payment data every day. Without a structured relational database and analytical queries, it is difficult to answer questions such as:

- Who are the highest-value customers?
- Which products generate the most revenue?
- Which categories perform best?
- What is the average order value?
- Which customers are repeat customers?
- Which products have weak sales?
- When are the busiest ordering periods?
- How does revenue change over time?

This project organizes the data into a normalized relational model and uses SQL to answer these business questions.

---

## 3. Project Objectives

1. Design a normalized relational database for cafe operations.
2. Establish appropriate primary and foreign key relationships.
3. Create realistic transactional and master data.
4. Analyze customers, products, orders, payments, and revenue.
5. Practice SQL JOINs, aggregations, CASE expressions, subqueries, CTEs, and window functions.
6. Create indexes for frequently queried columns and improve query performance.
7. Build reusable SQL Views.
8. Build parameterized Stored Procedures.
9. Implement Triggers for validation/auditing use cases.
10. Document the project so the analysis can be reproduced and presented.

---

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| MySQL | Relational database, SQL queries, views, procedures, triggers, and indexes |
| MySQL Workbench | Database development, execution, and ER diagram |
| GitHub | Version control and project documentation |

---

## 5. Database Schema

The database contains seven core tables:

| Table | Purpose |
|---|---|
| `Customers` | Customer master information |
| `Orders` | Order-level transaction information |
| `OrderItems` | Individual products contained in each order |
| `Products` | Cafe menu/product information |
| `Categories` | Product category master |
| `Payments` | Payment transactions |
| `Employees` | Employees handling customer orders |

### Relationship summary

- One customer can place many orders.
- One employee can handle many orders.
- One order can contain many order items.
- One product can appear in many order items.
- One category can contain many products.
- One order can have payment records.

The detailed ER diagram is available here:

`ER_Diagram/cafe_customer_analysis_er_diagram.png`

---

## 6. ER Diagram

![Cafe Customer Analysis ER Diagram](ER_Diagram/cafe_customer_analysis_er_diagram.png)

---

## 7. Database Workflow

```text
Business Requirements
        ↓
Identify Entities
        ↓
Define Relationships
        ↓
Create Database
        ↓
Create Tables
        ↓
Add Primary & Foreign Keys
        ↓
Insert / Validate Data
        ↓
Create Indexes
        ↓
Business Analysis
        ↓
Views
        ↓
Stored Procedures
        ↓
Triggers
        ↓
Business Insights
        ↓
Documentation & Presentation
```

---

## 8. SQL Analysis

The analysis will contain 20–30 business questions divided into:

### Customer Analysis

- Total customers
- Customer order frequency
- Customer lifetime spending
- Average customer spending
- Repeat customers
- Inactive customers
- Customers with no orders
- Customer segmentation
- Top customers by revenue

### Product Analysis

- Best-selling products
- Highest-revenue products
- Low-performing products
- Products with no orders
- Revenue by category
- Average selling price by category
- Product contribution to total revenue

### Order Analysis

- Total orders
- Average Order Value
- Daily order volume
- Monthly order trends
- Busy ordering hours
- Order status distribution

### Revenue & Payment Analysis

- Total revenue
- Monthly revenue
- Revenue growth
- Revenue by payment method
- Top revenue-generating customers
- Payment status analysis

---

## 9. SQL Concepts Demonstrated

The project is designed to demonstrate practical use of:

- `SELECT`
- `WHERE`
- `ORDER BY`
- `GROUP BY`
- Aggregate functions
- `INNER JOIN`
- `LEFT JOIN`
- `CASE`
- Subqueries
- Common Table Expressions (CTEs)
- Window functions
- `RANK()`
- `DENSE_RANK()`
- `ROW_NUMBER()`
- `SUM() OVER()`
- Indexes
- Views
- Stored Procedures
- Triggers
- Primary Keys
- Foreign Keys
- Constraints
- Data validation

---

## 10. Indexes

Indexes will be implemented to improve query performance on columns frequently used for searching, filtering, joining, and sorting.

Examples of columns that may require indexes include:

- `CustomerID`
- `OrderDate`
- `ProductID`
- `CategoryID`
- Payment-related columns where appropriate

The final index design will document:

- Index name
- Table and column(s)
- Purpose
- Query performance benefit

Indexes will be created based on the actual query patterns used in the project rather than adding unnecessary indexes.

---

## 11. Views

Planned reusable analytical views include:

### `vw_CustomerPurchaseSummary`

Provides customer-level metrics such as:

- Total orders
- Total quantity purchased
- Total spending
- Average order value
- Last order date

### `vw_ProductSalesSummary`

Provides product-level metrics such as:

- Quantity sold
- Revenue
- Number of orders
- Category
- Product performance

Views are used to avoid repeatedly writing the same complex joins and aggregations.

---

## 12. Stored Procedures

Planned parameterized procedures include:

```sql
SET @CustomerID = 105;
CALL sp_GetCustomerPurchaseHistory(@CustomerID);
```

```sql
SET @StartDate = '2026-01-01';
SET @EndDate = '2026-03-31';
CALL sp_GetSalesByDateRange(@StartDate, @EndDate);
```

```sql
SET @TopN = 10;
CALL sp_GetTopCustomers(@TopN);
```

These procedures demonstrate reusable, parameter-driven SQL logic.

---

## 13. Triggers

Triggers will be implemented only where there is a meaningful database use case.

Potential implementations include:

- Transaction/data validation
- Product price-change auditing
- Preventing invalid order quantities

The final trigger design will be documented together with its business reason and execution flow.

---

## 14. Sample Business Questions

Some of the questions the project will answer:

1. Who are the top 10 customers by total spending?
2. Which products are sold most frequently?
3. Which products generate the highest revenue?
4. What is the average order value?
5. Which category generates the most revenue?
6. Which customers have placed multiple orders?
7. Which customers have not ordered recently?
8. Which products have never been ordered?
9. What are the busiest ordering hours?
10. What is the monthly revenue trend?
11. Which payment method is used most frequently?
12. What percentage of revenue comes from each product category?
13. Which customers contribute the most to total revenue?
14. What is the average spending per customer?
15. How does product performance vary by category?

The final repository will contain detailed explanations for every business query.

---

## 15. Project Folder Structure

```text
Cafe-Customer-Analysis/
│
├── README.md
│
├── ER_Diagram/
│   └── cafe_customer_analysis_er_diagram.png
│
├── Database/
│   ├── 01_Create_Database.sql
│   ├── 02_Create_Tables.sql
│   ├── 03_Insert_Data.sql
│   └── 04_Constraints.sql
│
├── Indexes/
│   └── Cafe_Indexes.sql
│
├── Analysis/
│   ├── 01_Customer_Analysis.sql
│   ├── 02_Product_Analysis.sql
│   ├── 03_Order_Analysis.sql
│   ├── 04_Revenue_Analysis.sql
│   └── 05_Advanced_Analysis.sql
│
├── Views/
│   └── Cafe_Analysis_Views.sql
│
├── Stored_Procedures/
│   └── Cafe_Stored_Procedures.sql
│
├── Triggers/
│   ├── Cafe_Triggers.sql
│   └── Demo_Views_Procedures_Triggers.sql
│
├── Cafe_Customer_Analysis_All_In_One.sql
│
├── Documentation/
│   ├── Business_Requirements.md
│   ├── Data_Dictionary.md
│   └── Query_Explanations.md
│
└── Presentation/
    └── Cafe_Customer_Analysis.pptx
```

---

## 16. How to Run the Project

The final SQL scripts will be executed in this order:

```text
1. 01_Create_Database.sql
2. 02_Create_Tables.sql
3. 04_Constraints.sql
4. Indexes
5. 03_Insert_Data.sql
6. Triggers
7. Views
8. Stored Procedures
9. Analysis scripts
```

The trigger file is intentionally created after the seed data so the seed dataset
can be loaded with documented transaction values. The triggers then validate,
calculate, synchronize, and audit future transactions.

Open the scripts in **MySQL Workbench** and execute them in the documented order.

---

## 17. Expected Project Outcome

The completed project will provide:

- A normalized cafe database
- A documented ER diagram
- Realistic customer and transaction data
- 20–30 business analysis queries
- Advanced SQL analysis
- Performance-oriented indexes
- Reusable Views
- Parameterized Stored Procedures
- Practical Triggers
- Documented business insights
- GitHub-ready project structure
- Presentation-ready explanation

---

## 18. Future Enhancements

Possible extensions include:

- Power BI dashboard
- Customer RFM analysis
- Customer cohort analysis
- Sales forecasting
- Product profitability analysis
- Inventory management
- Promotion/coupon analysis
- Branch-level cafe analysis

---

## 19. Author

**Cafe Customer Analysis — MySQL Portfolio Project**

Built to demonstrate practical MySQL, database design, data analysis, query optimization, and business problem-solving skills.
