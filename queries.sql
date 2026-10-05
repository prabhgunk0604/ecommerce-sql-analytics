-- =====================================================
--  E-COMMERCE ANALYTICS: queries.sql  (SQLite)
--  Q1 - Q25, basic se advanced tak
--  Revenue ke liye hamesha status = 'Delivered' (cancelled ka paisa aaya hi nahi)
--  "Aaj" = dataset ki aakhri order date
-- =====================================================


-- ============ BUSINESS OVERVIEW ============

-- Q1. Headline KPIs: kitne orders, customers, revenue, profit, margin, avg order value
--     Concepts: aggregates, COUNT DISTINCT, view
SELECT COUNT(DISTINCT order_id)                                   AS delivered_orders,
       COUNT(DISTINCT customer_id)                                AS active_customers,
       ROUND(SUM(net_revenue))                                    AS revenue,
       ROUND(SUM(profit))                                         AS profit,
       ROUND(100.0 * SUM(profit) / SUM(net_revenue), 1)           AS margin_pct,
       ROUND(SUM(net_revenue) / COUNT(DISTINCT order_id))         AS avg_order_value
FROM v_sales
WHERE status = 'Delivered';


-- Q2. Monthly revenue aur Month-over-Month (MoM) growth %
--     Concepts: CTE, GROUP BY, strftime, LAG
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS ym,
           SUM(net_revenue)              AS rev
    FROM v_sales
    WHERE status = 'Delivered'
    GROUP BY ym
)
SELECT ym,
       ROUND(rev) AS revenue,
       ROUND(100.0 * (rev - LAG(rev) OVER (ORDER BY ym))
                   / LAG(rev) OVER (ORDER BY ym), 1) AS mom_growth_pct
FROM monthly
ORDER BY ym;


-- Q3. Year-over-Year (YoY): 2025 ka har mahina vs 2024 ka wahi mahina
--     Concepts: CTE, self join, date parts
WITH m AS (
    SELECT CAST(strftime('%Y', order_date) AS INTEGER) AS yr,
           strftime('%m', order_date)                  AS mon,
           SUM(net_revenue)                            AS rev
    FROM v_sales
    WHERE status = 'Delivered'
    GROUP BY yr, mon
)
SELECT cur.mon                                       AS month,
       ROUND(prev.rev)                               AS revenue_2024,
       ROUND(cur.rev)                                AS revenue_2025,
       ROUND(100.0 * (cur.rev - prev.rev) / prev.rev, 1) AS yoy_growth_pct
FROM m cur
JOIN m prev ON prev.mon = cur.mon AND prev.yr = cur.yr - 1
WHERE cur.yr = 2025
ORDER BY cur.mon;


-- Q4. Category-wise revenue, profit, margin aur revenue share %
--     Concepts: JOIN, GROUP BY, SUM(SUM()) OVER ()
SELECT c.category_name,
       ROUND(SUM(s.net_revenue))                                          AS revenue,
       ROUND(SUM(s.profit))                                               AS profit,
       ROUND(100.0 * SUM(s.profit) / SUM(s.net_revenue), 1)               AS margin_pct,
       ROUND(100.0 * SUM(s.net_revenue) / SUM(SUM(s.net_revenue)) OVER (), 1) AS revenue_share_pct
FROM v_sales s
JOIN categories c ON c.category_id = s.category_id
WHERE s.status = 'Delivered'
GROUP BY c.category_name
ORDER BY revenue DESC;


-- Q5. Har category ke top 3 products (revenue ke hisaab se)
--     Concepts: RANK + PARTITION BY, CTE, rank pe filter
WITH prod_rev AS (
    SELECT c.category_name,
           p.product_name,
           SUM(s.net_revenue) AS revenue,
           RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(s.net_revenue) DESC) AS rnk
    FROM v_sales s
    JOIN products   p ON p.product_id   = s.product_id
    JOIN categories c ON c.category_id  = p.category_id
    WHERE s.status = 'Delivered'
    GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
)
SELECT category_name, product_name, ROUND(revenue) AS revenue, rnk
FROM prod_rev
WHERE rnk <= 3
ORDER BY category_name, rnk;


-- Q6. Top 10 cities (revenue), orders aur customers ke saath
--     Concepts: JOIN, RANK, COUNT DISTINCT, LIMIT
SELECT cu.city,
       cu.region,
       COUNT(DISTINCT s.order_id)    AS orders,
       COUNT(DISTINCT s.customer_id) AS customers,
       ROUND(SUM(s.net_revenue))     AS revenue,
       RANK() OVER (ORDER BY SUM(s.net_revenue) DESC) AS rnk
FROM v_sales s
JOIN customers cu ON cu.customer_id = s.customer_id
WHERE s.status = 'Delivered'
GROUP BY cu.city, cu.region
ORDER BY revenue DESC
LIMIT 10;


-- ============ PAYMENTS, CANCELS, RETURNS, DELIVERY ============

-- Q7. Payment method ke hisaab se orders, cancel rate aur order share
--     Concepts: JOIN, conditional aggregation, window %
SELECT p.method,
       COUNT(*)                                                           AS orders,
       SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END)            AS cancelled,
       ROUND(100.0 * SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                 AS order_share_pct
FROM payments p
JOIN orders o ON o.order_id = p.order_id
GROUP BY p.method
ORDER BY orders DESC;


-- Q8. Category-wise return rate (cancelled orders chhod ke)
--     Concepts: JOIN, conditional aggregation (COUNT DISTINCT + CASE)
SELECT c.category_name,
       COUNT(DISTINCT s.order_id) AS orders,
       COUNT(DISTINCT CASE WHEN s.status = 'Returned' THEN s.order_id END) AS returned_orders,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.status = 'Returned' THEN s.order_id END)
                   / COUNT(DISTINCT s.order_id), 1) AS return_rate_pct
FROM v_sales s
JOIN categories c ON c.category_id = s.category_id
WHERE s.status <> 'Cancelled'
GROUP BY c.category_name
ORDER BY return_rate_pct DESC;


-- Q12. Region-wise delivery performance (kitne orders 3 din ya kam mein pahunche)
--      Concepts: CTE, conditional aggregation
WITH deliv AS (
    SELECT cu.region, o.delivery_days
    FROM orders o
    JOIN customers cu ON cu.customer_id = o.customer_id
    WHERE o.status IN ('Delivered', 'Returned')      -- jinki delivery hui
)
SELECT region,
       COUNT(*)                                                     AS orders,
       ROUND(AVG(delivery_days), 2)                                 AS avg_days,
       SUM(CASE WHEN delivery_days <= 3 THEN 1 ELSE 0 END)          AS fast_orders,
       ROUND(100.0 * SUM(CASE WHEN delivery_days <= 3 THEN 1 ELSE 0 END) / COUNT(*), 1) AS fast_pct,
       MAX(delivery_days)                                           AS slowest
FROM deliv
GROUP BY region
ORDER BY avg_days;


-- ============ CUSTOMER ANALYTICS (RFM, Pareto, Cohort) ============

-- Q9. RFM scores (1-5) har customer ke liye
--     Concepts: 4-CTE chain (cust -> ref -> rfm -> scored), CROSS JOIN, julianday, NTILE
WITH cust AS (                                         -- step 1: har customer ka summary
    SELECT customer_id,
           MAX(order_date) AS last_order,
           COUNT(*)        AS frequency,
           SUM(order_value) AS monetary
    FROM v_orders_delivered
    GROUP BY customer_id
),
ref AS (                                               -- step 2: "aaj" ki date
    SELECT MAX(order_date) AS today FROM v_orders_delivered
),
rfm AS (                                               -- step 3: recency (din)
    SELECT c.customer_id,
           CAST(julianday(r.today) - julianday(c.last_order) AS INTEGER) AS recency_days,
           c.frequency,
           ROUND(c.monetary) AS monetary
    FROM cust c
    CROSS JOIN ref r
),
scored AS (                                            -- step 4: NTILE(5) scores, 5 = achha
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency)         AS f_score,
           NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM rfm
)
SELECT *
FROM scored
ORDER BY r_score DESC, f_score DESC, m_score DESC
LIMIT 20;


-- Q10. RFM segments: Champions, Loyal, At Risk, ... aur unka share
--      Concepts: NTILE, CASE segmentation, window %
WITH cust AS (
    SELECT customer_id, MAX(order_date) AS last_order, COUNT(*) AS frequency, SUM(order_value) AS monetary
    FROM v_orders_delivered
    GROUP BY customer_id
),
ref AS (SELECT MAX(order_date) AS today FROM v_orders_delivered),
rfm AS (
    SELECT c.customer_id,
           CAST(julianday(r.today) - julianday(c.last_order) AS INTEGER) AS recency_days,
           c.frequency, c.monetary
    FROM cust c CROSS JOIN ref r
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency)         AS f_score
    FROM rfm
),
segmented AS (
    SELECT customer_id, monetary,
           CASE WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
                WHEN f_score >= 4                  THEN 'Loyal'
                WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
                WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
                WHEN r_score <= 2                  THEN 'Lost'
                ELSE 'Regular' END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                                  AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_customers,
       ROUND(SUM(monetary))                                      AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;


-- Q11. Pareto (80-20): customers ko 5 barabar groups mein baanto, cumulative revenue share
--      Concepts: NTILE, SUM(SUM()) OVER, cumulative %
WITH per_cust AS (
    SELECT customer_id, SUM(order_value) AS spend
    FROM v_orders_delivered
    GROUP BY customer_id
),
quint AS (
    SELECT customer_id, spend,
           NTILE(5) OVER (ORDER BY spend DESC) AS quintile      -- 1 = top 20% customers
    FROM per_cust
),
agg AS (
    SELECT quintile,
           COUNT(*)   AS customers,
           SUM(spend) AS revenue,
           100.0 * SUM(spend) / SUM(SUM(spend)) OVER () AS share_pct
    FROM quint
    GROUP BY quintile
)
SELECT quintile,
       customers,
       ROUND(revenue)                                  AS revenue,
       ROUND(share_pct, 1)                             AS revenue_share_pct,
       ROUND(SUM(share_pct) OVER (ORDER BY quintile), 1) AS cumulative_share_pct
FROM agg
ORDER BY quintile;


-- Q13. Cohort retention: pehle order ke mahine ke group ne baad ke mahino mein kitna % wapas kharida
--      Concepts: cohort logic, DISTINCT, date math, CTE chain
WITH first_order AS (
    SELECT customer_id,
           strftime('%Y-%m', MIN(order_date)) AS cohort
    FROM v_orders_delivered
    GROUP BY customer_id
),
activity AS (                                           -- cohort se kitne mahine baad order hua
    SELECT DISTINCT d.customer_id, f.cohort,
           (CAST(strftime('%Y', d.order_date) AS INTEGER) - CAST(substr(f.cohort, 1, 4) AS INTEGER)) * 12
         + (CAST(strftime('%m', d.order_date) AS INTEGER) - CAST(substr(f.cohort, 6, 2) AS INTEGER)) AS month_no
    FROM v_orders_delivered d
    JOIN first_order f ON f.customer_id = d.customer_id
),
sizes AS (
    SELECT cohort, COUNT(*) AS cohort_size FROM first_order GROUP BY cohort
)
SELECT a.cohort,
       s.cohort_size,
       ROUND(100.0 * SUM(CASE WHEN a.month_no = 1 THEN 1 ELSE 0 END) / s.cohort_size, 1) AS m1_pct,
       ROUND(100.0 * SUM(CASE WHEN a.month_no = 2 THEN 1 ELSE 0 END) / s.cohort_size, 1) AS m2_pct,
       ROUND(100.0 * SUM(CASE WHEN a.month_no = 3 THEN 1 ELSE 0 END) / s.cohort_size, 1) AS m3_pct,
       ROUND(100.0 * SUM(CASE WHEN a.month_no = 6 THEN 1 ELSE 0 END) / s.cohort_size, 1) AS m6_pct
FROM activity a
JOIN sizes s ON s.cohort = a.cohort
GROUP BY a.cohort, s.cohort_size
ORDER BY a.cohort;


-- Q14. New vs Returning customers ka monthly revenue
--      Concepts: ROW_NUMBER + PARTITION BY, conditional SUM
WITH numbered AS (
    SELECT order_id, customer_id, order_date, order_value,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS order_no
    FROM v_orders_delivered
)
SELECT strftime('%Y-%m', order_date) AS ym,
       ROUND(SUM(CASE WHEN order_no = 1 THEN order_value ELSE 0 END)) AS new_customer_rev,
       ROUND(SUM(CASE WHEN order_no > 1 THEN order_value ELSE 0 END)) AS returning_rev,
       ROUND(100.0 * SUM(CASE WHEN order_no > 1 THEN order_value ELSE 0 END) / SUM(order_value), 1) AS returning_pct
FROM numbered
GROUP BY ym
ORDER BY ym;


-- Q15. Do orders ke beech ka gap (reorder gap) aur uske buckets
--      Concepts: LAG + PARTITION BY, CASE bucketing, window %
WITH gaps AS (
    SELECT customer_id, order_date,
           CAST(julianday(order_date)
              - julianday(LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, order_id)) AS INTEGER) AS gap_days
    FROM v_orders_delivered
)
SELECT CASE WHEN gap_days <= 30 THEN 'a) 0-30 days'
            WHEN gap_days <= 60 THEN 'b) 31-60 days'
            WHEN gap_days <= 90 THEN 'c) 61-90 days'
            ELSE                     'd) 90+ days' END AS gap_bucket,
       COUNT(*)                                          AS reorders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_reorders
FROM gaps
WHERE gap_days IS NOT NULL                                -- pehle order ka gap NULL hota hai
GROUP BY gap_bucket
ORDER BY gap_bucket;


-- Q16. Customers kitne din se inactive hain (churn risk)
--      Concepts: CROSS JOIN, CASE, date diff
WITH last_o AS (
    SELECT customer_id, MAX(order_date) AS last_order
    FROM v_orders_delivered
    GROUP BY customer_id
),
ref AS (SELECT MAX(order_date) AS today FROM v_orders_delivered),
days_since AS (
    SELECT l.customer_id,
           CAST(julianday(r.today) - julianday(l.last_order) AS INTEGER) AS d
    FROM last_o l CROSS JOIN ref r
)
SELECT CASE WHEN d <= 30  THEN 'a) 0-30 days (active)'
            WHEN d <= 90  THEN 'b) 31-90 days'
            WHEN d <= 180 THEN 'c) 91-180 days (cooling)'
            ELSE               'd) 180+ days (churn risk)' END AS inactivity_bucket,
       COUNT(*)                                           AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers
FROM days_since
GROUP BY inactivity_bucket
ORDER BY inactivity_bucket;


-- Q17a. Signup kiya par kabhi order nahi kiya (kuch bhi)
--       Concepts: LEFT JOIN ... IS NULL
SELECT c.customer_id, c.full_name, c.city, c.signup_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date
LIMIT 20;

-- Q17b. Aise customers kitne hain aur total ka kitna %
--       Concepts: LEFT JOIN, scalar subquery
SELECT COUNT(*) AS never_ordered,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 1) AS pct_of_all_customers
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;


-- Q21. Pehle order ki category kaunsi thi, aur kis category se aaye customers wapas aate hain?
--      Concepts: ROW_NUMBER, COUNT OVER PARTITION, DISTINCT
WITH ord AS (
    SELECT order_id, customer_id,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS order_no,
           COUNT(*)     OVER (PARTITION BY customer_id)                                AS total_orders
    FROM v_orders_delivered
),
first_cat AS (                                           -- pehle order ki category(ies)
    SELECT DISTINCT o.customer_id, o.total_orders, p.category_id
    FROM ord o
    JOIN order_items oi ON oi.order_id   = o.order_id
    JOIN products    p  ON p.product_id  = oi.product_id
    WHERE o.order_no = 1
)
SELECT c.category_name AS first_order_category,
       COUNT(*)        AS customers,
       SUM(CASE WHEN f.total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(100.0 * SUM(CASE WHEN f.total_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM first_cat f
JOIN categories c ON c.category_id = f.category_id
GROUP BY c.category_name
ORDER BY repeat_rate_pct DESC;


-- ============ SALES PATTERNS & PRICING ============

-- Q18. Monthly revenue ka running total aur 3-month moving average
--      Concepts: running total, moving average (frame)
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS ym, SUM(net_revenue) AS rev
    FROM v_sales
    WHERE status = 'Delivered'
    GROUP BY ym
)
SELECT ym,
       ROUND(rev)                                                          AS revenue,
       ROUND(SUM(rev) OVER (ORDER BY ym))                                  AS running_total,
       ROUND(AVG(rev) OVER (ORDER BY ym ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) AS moving_avg_3m
FROM monthly
ORDER BY ym;


-- Q19. Discount bands vs margin: zyada discount se profit kitna girta hai?
--      Concepts: CASE bucketing, margin math
SELECT CASE WHEN discount_pct = 0  THEN 'a) No discount'
            WHEN discount_pct <= 10 THEN 'b) 5-10%'
            WHEN discount_pct <= 20 THEN 'c) 15-20%'
            ELSE                         'd) 30%' END AS discount_band,
       COUNT(*)                                        AS order_lines,
       SUM(quantity)                                   AS units,
       ROUND(SUM(net_revenue))                         AS revenue,
       ROUND(SUM(profit))                              AS profit,
       ROUND(100.0 * SUM(profit) / SUM(net_revenue), 1) AS margin_pct
FROM v_sales
WHERE status = 'Delivered'
GROUP BY discount_band
ORDER BY discount_band;


-- Q20. Market basket: kaunse 2 products sabse zyada ek saath bikte hain
--      Concepts: self join
SELECT p1.product_name AS product_a,
       p2.product_name AS product_b,
       COUNT(*)        AS orders_together
FROM order_items a
JOIN order_items b ON b.order_id = a.order_id          -- same order
                  AND a.product_id < b.product_id      -- pair ek hi baar aaye
JOIN products p1 ON p1.product_id = a.product_id
JOIN products p2 ON p2.product_id = b.product_id
JOIN orders   o  ON o.order_id    = a.order_id
WHERE o.status = 'Delivered'
GROUP BY a.product_id, b.product_id, p1.product_name, p2.product_name
ORDER BY orders_together DESC
LIMIT 10;


-- Q22. Din-wise (Mon-Sun) orders, revenue aur avg order value, weekend vs weekday
--      Concepts: strftime weekday, CASE
WITH d AS (
    SELECT strftime('%w', order_date) AS dow, order_value
    FROM v_orders_delivered
)
SELECT CASE dow WHEN '0' THEN 'Sunday'   WHEN '1' THEN 'Monday'  WHEN '2' THEN 'Tuesday'
                WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday' WHEN '5' THEN 'Friday'
                ELSE 'Saturday' END                                     AS weekday,
       CASE WHEN dow IN ('0', '6') THEN 'Weekend' ELSE 'Weekday' END    AS day_type,
       COUNT(*)                  AS orders,
       ROUND(SUM(order_value))   AS revenue,
       ROUND(AVG(order_value))   AS avg_order_value
FROM d
GROUP BY dow
ORDER BY dow;


-- Q23. Festive season (Oct-Nov) vs baaki mahine: avg order value (saal-wise)
--      Concepts: conditional aggregation, NULL trick with AVG
--      (CASE mein ELSE nahi likha, toh baaki rows NULL hongi aur AVG unhe ignore karega)
WITH x AS (
    SELECT strftime('%Y', order_date) AS yr,
           SUM(CASE WHEN strftime('%m', order_date) IN ('10', '11') THEN 1 ELSE 0 END) AS festive_orders,
           SUM(CASE WHEN strftime('%m', order_date) NOT IN ('10', '11') THEN 1 ELSE 0 END) AS normal_orders,
           AVG(CASE WHEN strftime('%m', order_date) IN ('10', '11') THEN order_value END)     AS festive_aov,
           AVG(CASE WHEN strftime('%m', order_date) NOT IN ('10', '11') THEN order_value END) AS normal_aov
    FROM v_orders_delivered
    GROUP BY yr
)
SELECT yr, festive_orders, normal_orders,
       ROUND(festive_aov) AS festive_aov,
       ROUND(normal_aov)  AS normal_aov,
       ROUND(100.0 * (festive_aov - normal_aov) / normal_aov, 1) AS festive_uplift_pct
FROM x
ORDER BY yr;


-- Q24. Order value buckets: kitne orders chhote/bade aur revenue mein unka hissa
--      Concepts: CASE bucketing on numeric column
SELECT CASE WHEN order_value < 1000  THEN 'a) Under 1,000'
            WHEN order_value < 5000  THEN 'b) 1,000 - 4,999'
            WHEN order_value < 20000 THEN 'c) 5,000 - 19,999'
            ELSE                          'd) 20,000+' END AS value_bucket,
       COUNT(*)                                                 AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)       AS pct_orders,
       ROUND(SUM(order_value))                                  AS revenue,
       ROUND(100.0 * SUM(order_value) / SUM(SUM(order_value)) OVER (), 1) AS pct_revenue
FROM v_orders_delivered
GROUP BY value_bucket
ORDER BY value_bucket;


-- Q25. Har category ke top 2 brands aur category mein unka share
--      Concepts: CTE, RANK + PARTITION BY, window %
WITH brand_rev AS (
    SELECT c.category_name, p.brand, SUM(s.net_revenue) AS revenue
    FROM v_sales s
    JOIN products   p ON p.product_id  = s.product_id
    JOIN categories c ON c.category_id = p.category_id
    WHERE s.status = 'Delivered'
    GROUP BY c.category_name, p.brand
),
ranked AS (
    SELECT category_name, brand, revenue,
           RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rnk,
           100.0 * revenue / SUM(revenue) OVER (PARTITION BY category_name) AS share_pct
    FROM brand_rev
)
SELECT category_name, brand, ROUND(revenue) AS revenue, ROUND(share_pct, 1) AS share_in_category_pct, rnk
FROM ranked
WHERE rnk <= 2
ORDER BY category_name, rnk;
