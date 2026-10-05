# E-Commerce SQL Analytics — SQLite

## Project Overview

This project analyzes an e-commerce database using SQL and SQLite to answer real-world business questions and generate actionable insights.

The project includes a relational database, sample e-commerce data, and 25 SQL analytics queries covering customers, products, orders, sales, and revenue.

## Objectives

- Analyze customer purchasing behavior
- Identify top-performing products
- Analyze sales and revenue trends
- Answer business-focused questions using SQL
- Practice relational database analysis with SQLite

## Database

The project uses SQLite and includes the following main tables:

- Customers
- Products
- Orders
- Order Items
- Categories
- Payments
- 
## Tech Stack

- **Database:** SQLite
- **Query Language:** SQL
- **Programming Language:** Python
- **Database Tool:** DB Browser for SQLite
- **Version Control:** Git & GitHub
- 
## Project Highlights

- Designed a relational e-commerce database using SQLite.
- Created and managed 6 interconnected tables with primary and foreign keys.
- Built reusable SQL views for sales and delivered-order analysis.
- Added indexes to improve query performance.
- Performed revenue, profit, margin, customer, product, and category analysis.
- Applied advanced SQL techniques including:
  - Window Functions
  - CTEs
  - RFM Analysis
  - Cohort Analysis
  - Pareto Analysis
  - Market Basket Analysis
  - Customer Churn Analysis
  - Moving Averages
  - Running Totals
- Analyzed customer retention, repeat purchases, discounts, returns, and payment behavior.
## Database Schema

The database is designed around the following core entities:

- **Customers** — customer information
- **Products** — product details and pricing
- **Categories** — product categories
- **Orders** — customer orders
- **Order Items** — products included in each order
- **Payments** — payment information

### Relationships

```text
Customers
    │
    └── Orders
           │
           └── Order Items ─── Products
                                  │
                                  └── Categories

Orders
   │
   └── Payments
## SQL Analysis

The project contains 25 SQL queries covering:

- Revenue analysis
- Customer analysis
- Product performance
- Order analysis
- Sales trends
- Business performance metrics

## Tools & Technologies

- SQL
- SQLite
- Python
- Git & GitHub
- DB Browser for SQLite

## Project Structure

```text
ecommerce-sql-analytics/
├── ecommerce.db
├── schema.sql
├── queries.sql
├── generate_data.py
└── README.md
## How to Run

1. Download or clone this repository.
2. Open `ecommerce.db` using DB Browser for SQLite.
3. Open `queries.sql`.
4. Execute the SQL queries to explore the analysis.

## Key Insights

The analysis provides insights into customer behavior, product performance, revenue generation, and overall e-commerce sales trends.

## Author

**Prabhgun**
