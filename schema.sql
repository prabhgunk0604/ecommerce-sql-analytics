---- =====================================================
-- E-COMMERCE DATABASE: schema.sql (SQLite)
-- 6 Tables + 2 Views + Performance Indexes
-- =====================================================

PRAGMA foreign_keys = ON;

-- =====================================================
-- CLEANUP: Drop Existing Views and Tables
-- =====================================================

DROP VIEW IF EXISTS v_orders_delivered;
DROP VIEW IF EXISTS v_sales;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;


-- =====================================================
-- TABLE 1: Categories
-- Stores product category information.
-- =====================================================

CREATE TABLE categories (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL UNIQUE
);


-- =====================================================
-- TABLE 2: Products
-- Stores product details, pricing, brand, and category.
-- =====================================================

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category_id   INTEGER NOT NULL
                  REFERENCES categories(category_id),
    brand         TEXT NOT NULL,
    unit_price    REAL NOT NULL CHECK (unit_price > 0),
    cost_price    REAL NOT NULL CHECK (cost_price > 0)
);


-- =====================================================
-- TABLE 3: Customers
-- Stores customer profile and location information.
-- signup_date format: YYYY-MM-DD
-- =====================================================

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    full_name    TEXT NOT NULL,
    email        TEXT NOT NULL UNIQUE,
    city         TEXT NOT NULL,
    state        TEXT NOT NULL,
    region       TEXT NOT NULL
                 CHECK (region IN ('North', 'South', 'East', 'West')),
    signup_date  TEXT NOT NULL
);


-- =====================================================
-- TABLE 4: Orders
-- Stores customer orders, order status, and delivery time.
-- delivery_days can be NULL for cancelled orders.
-- =====================================================

CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL
                   REFERENCES customers(customer_id),
    order_date     TEXT NOT NULL,
    status         TEXT NOT NULL
                   CHECK (status IN ('Delivered', 'Cancelled', 'Returned')),
    delivery_days  INTEGER
);


-- =====================================================
-- TABLE 5: Order Items
-- Stores individual products included in each order.
-- =====================================================

CREATE TABLE order_items (
    item_id       INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL
                  REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL
                  REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    REAL NOT NULL,
    discount_pct  INTEGER NOT NULL DEFAULT 0
                  CHECK (discount_pct BETWEEN 0 AND 100)
);


-- =====================================================
-- TABLE 6: Payments
-- Stores payment method, amount, and payment status.
-- Each order can have only one payment record.
-- =====================================================

CREATE TABLE payments (
    payment_id      INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL UNIQUE
                    REFERENCES orders(order_id),
    method          TEXT NOT NULL
                    CHECK (method IN (
                        'UPI',
                        'Card',
                        'NetBanking',
                        'Wallet',
                        'COD'
                    )),
    amount          REAL NOT NULL,
    payment_status  TEXT NOT NULL
                    CHECK (payment_status IN (
                        'Paid',
                        'Voided',
                        'Refunded'
                    ))
);


-- =====================================================
-- INDEXES
-- Improve query performance for frequently used
-- JOIN and WHERE columns.
-- =====================================================

CREATE INDEX idx_orders_customer
    ON orders(customer_id);

CREATE INDEX idx_orders_date
    ON orders(order_date);

CREATE INDEX idx_items_order
    ON order_items(order_id);

CREATE INDEX idx_items_product
    ON order_items(product_id);

CREATE INDEX idx_products_category
    ON products(category_id);


-- =====================================================
-- VIEW 1: Sales Analysis
-- One row per order item with calculated revenue
-- and profit.
-- =====================================================

CREATE VIEW v_sales AS
SELECT
    oi.item_id,
    oi.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    p.category_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,

    ROUND(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount_pct / 100.0),
        2
    ) AS net_revenue,

    ROUND(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount_pct / 100.0)
        - oi.quantity * p.cost_price,
        2
    ) AS profit

FROM order_items oi
JOIN orders o
    ON o.order_id = oi.order_id
JOIN products p
    ON p.product_id = oi.product_id;


-- =====================================================
-- VIEW 2: Delivered Order Summary
-- One row per delivered order with its total value.
-- =====================================================

CREATE VIEW v_orders_delivered AS
SELECT
    order_id,
    customer_id,
    order_date,
    ROUND(SUM(net_revenue), 2) AS order_value

FROM v_sales

WHERE status = 'Delivered'

GROUP BY
    order_id,
    customer_id,
    order_date;
