# E-commerce SQL Project (SQLite)

Online shopping store ka database + 25 analytics queries (basic se advanced).

## Files

| File | Kya hai |
|---|---|
| `ecommerce.db` | Ready database (isse seedha khol sakte ho) |
| `schema.sql` | 6 tables, indexes aur 2 views (`v_sales`, `v_orders_delivered`) |
| `generate_data.py` | `schema.sql` chalake data bharta hai (db dobara banane ke liye) |
| `queries.sql` | Q1 se Q25 tak saari queries, comments ke saath |

## Kaise chalayein

**Option 1: DB Browser for SQLite (sabse aasan)**
1. `ecommerce.db` kholo, `Browse Data` tab mein tables dekho.
2. `Execute SQL` tab mein `queries.sql` se ek query copy-paste karke chalao.

**Option 2: Terminal**
```bash
python generate_data.py                      # (optional) db dobara banane ke liye
sqlite3 ecommerce.db < queries.sql           # saari queries ek saath
sqlite3 -header -column ecommerce.db         # interactive mode
```

## Tables

```
customers --(customer_id)--< orders --(order_id)--< order_items >--(product_id)-- products --(category_id)-- categories
                               |
                               +--(order_id)-- payments
```

| Table | Rows | Kya store karti hai |
|---|---|---|
| categories | 6 | Product categories |
| products | 60 | Products, selling price aur cost price |
| customers | 2,500 | Customer, city, region, signup date |
| orders | ~7,200 | Har order (status: Delivered / Cancelled / Returned) |
| order_items | ~13,600 | Order ke andar ke products, quantity, discount |
| payments | ~7,200 | Har order ka payment (method, amount, status) |

Views:
- `v_sales`: ek row per order line, `net_revenue` aur `profit` ke saath
- `v_orders_delivered`: ek row per delivered order, uski `order_value`

## Queries ka index

| Query | Topic | Main concepts |
|---|---|---|
| Q1 | Headline KPIs | Aggregates, COUNT DISTINCT |
| Q2 | Monthly revenue + MoM growth | CTE, LAG |
| Q3 | YoY growth | Self join |
| Q4 | Category revenue share | `SUM(SUM()) OVER ()` |
| Q5 | Top 3 products per category | RANK + PARTITION BY |
| Q6 | Top 10 cities | JOIN, RANK, LIMIT |
| Q7 | Payment method cancel rate | Conditional aggregation |
| Q8 | Category return rate | COUNT DISTINCT + CASE |
| Q9 | RFM scores | 4-CTE chain, CROSS JOIN, NTILE |
| Q10 | RFM segments | CASE segmentation |
| Q11 | Pareto (80-20) | NTILE, cumulative % |
| Q12 | Region delivery performance | CTE, conditional aggregation |
| Q13 | Cohort retention | Cohort logic, date math |
| Q14 | New vs returning revenue | ROW_NUMBER |
| Q15 | Reorder gap buckets | LAG + PARTITION BY |
| Q16 | Customer inactivity | CROSS JOIN, CASE |
| Q17 | Never ordered customers | LEFT JOIN ... IS NULL |
| Q18 | Running total + moving avg | Window frame |
| Q19 | Discount band vs margin | CASE bucketing |
| Q20 | Market basket | Self join |
| Q21 | First-order category vs repeat | ROW_NUMBER, COUNT OVER |
| Q22 | Weekday sales | strftime |
| Q23 | Festive vs normal AOV | NULL trick with AVG |
| Q24 | Order value buckets | CASE on numeric column |
| Q25 | Top brands per category | RANK, window % |

## Dusre database mein chalane ke liye (conversion)

| SQLite | MySQL | PostgreSQL |
|---|---|---|
| `strftime('%Y-%m', d)` | `DATE_FORMAT(d, '%Y-%m')` | `TO_CHAR(d, 'YYYY-MM')` |
| `strftime('%w', d)` | `DAYOFWEEK(d) - 1` | `EXTRACT(DOW FROM d)` |
| `julianday(a) - julianday(b)` | `DATEDIFF(a, b)` | `a - b` (dates) |

## Results (key queries ke screenshots)

Saari 25 queries `queries.sql` mein hain. Neeche 6 main queries ke output hain (Jupyter mein chalaye).

### Q1: Headline KPIs
![Q1](screenshots/q1.png)
Store ne ~6,300 delivered orders se ~15.8 million ka revenue kamaya.

### Q4: Category-wise revenue
![Q4](screenshots/q4.png)
Electronics sabse badi category hai, ~43% revenue share ke saath.

### Q5: Har category ke top 3 products
![Q5](screenshots/q5.png)
Electronics mein Laptop ProBook 14 sabse zyada revenue deta hai.

### Q7: Payment method ke hisaab se cancel rate
![Q7](screenshots/q7.png)
COD ka cancel rate sabse zyada hai (~14.7%), baaki methods ka ~6%.

### Q11: Pareto (80-20)
![Q11](screenshots/q11.png)
Top 20% customers ~64% revenue dete hain.

### Q20: Market basket
![Q20](screenshots/q20.png)
Notebook A4 aur Gel Pen Set sabse zyada saath mein bikte hain (~300 orders).

## Note

Data synthetic (random, `seed=42`) hai, toh numbers har baar same aayenge, par kisi purani guide ke numbers se exact match nahi honge. Table structure, columns aur queries wahi hain.
