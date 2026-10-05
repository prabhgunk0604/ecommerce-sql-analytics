# E-Commerce SQL Analytics

A SQL-based e-commerce analytics project built with **SQLite** to analyze sales performance, customer behavior, product performance, profitability, retention, and purchasing patterns.

## Project Overview

This project uses a relational e-commerce database and a collection of analytical SQL queries to answer real-world business questions.

The analysis covers:

* Sales and revenue performance
* Product and category performance
* Customer behavior and segmentation
* Customer retention and churn
* Regional and city-level performance
* Payment and cancellation analysis
* Discounts and profitability
* Market basket analysis
* Cohort and repeat-purchase analysis

## Tech Stack

* **Database:** SQLite
* **Query Language:** SQL
* **Programming Language:** Python
* **Database Tool:** DB Browser for SQLite
* **Version Control:** Git & GitHub

## Project Highlights

* Designed a relational e-commerce database using SQLite.
* Created 6 interconnected tables using primary and foreign keys.
* Built reusable SQL views for sales and delivered-order analysis.
* Added indexes to improve query performance.
* Developed 25 analytical SQL queries.
* Applied advanced SQL techniques including:

  * Window Functions
  * CTEs
  * RFM Analysis
  * Cohort Analysis
  * Pareto Analysis
  * Market Basket Analysis
  * Churn Analysis
  * Moving Averages
  * Running Totals

## Database Schema

The database contains the following core entities:

* **Customers** — customer information
* **Products** — product details and pricing
* **Categories** — product categories
* **Orders** — customer orders
* **Order Items** — products included in each order
* **Payments** — payment information

### Relationships

```text
Customers
    │
    └── Orders
           │
           ├── Order Items ─── Products
           │                       │
           │                       └── Categories
           │
           └── Payments
```

## SQL Analysis

The project contains **25 analytical SQL queries** covering:

| Area            | Analysis                                    |
| --------------- | ------------------------------------------- |
| Sales           | Revenue, profit, margin, AOV                |
| Products        | Top products and brands                     |
| Categories      | Revenue, profit, returns                    |
| Customers       | RFM, churn, retention, repeat purchases     |
| Geography       | City and regional performance               |
| Payments        | Payment methods and cancellation rate       |
| Retention       | Cohort analysis and reorder behavior        |
| Basket Analysis | Frequently purchased product combinations   |
| Time Analysis   | Monthly trends, YoY growth, moving averages |

## Query Results

Sample outputs from the SQL analysis:

### Q1 — Headline Business KPIs

![Q1 Results](screenshots/q1.png)

### Q4 — Category Performance

![Q4 Results](screenshots/q4.png)

### Q5 — Top Products by Category

![Q5 Results](screenshots/q5.png)

### Q7 — Payment Method Analysis

![Q7 Results](screenshots/q7.png)

### Q11 — Customer Revenue Pareto Analysis

![Q11 Results](screenshots/q11.png)

### Q20 — Market Basket Analysis

![Q20 Results](screenshots/q20.png)

## Project Structure

```text
ecommerce-sql-analytics/
│
├── README.md
├── schema.sql
├── queries.sql
├── generate_data.py
├── ecommerce.db
├── er_diagram.png
│
└── screenshots/
    ├── q1.png
    ├── q4.png
    ├── q5.png
    ├── q7.png
    ├── q11.png
    └── q20.png
```

## How to Run

1. Clone or download this repository.
2. Open `ecommerce.db` using DB Browser for SQLite.
3. Open `queries.sql`.
4. Execute the SQL queries to explore the analysis.

## Key Insights

The analysis provides insights into customer behavior, product performance, revenue generation, profitability, retention, and overall e-commerce sales trends.

## Author

**Prabhgun**
