---checking any duplicates tables before creating one---

DROP TABLE IF EXISTS ORDER_ITEMS CASCADE;
DROP TABLE IF EXISTS ORDERS CASCADE;
DROP TABLE IF EXISTS PRODUCTS CASCADE;
DROP TABLE IF EXISTS AISELS CASCADE;
DROP TABLE IF EXISTS DEPARTMENTS CASCADE;


----creating tables before importing dataset---
CREATE TABLE DEPARTMENTS(
	DEPARTMENT_ID INTEGER PRIMARY KEY,
	DEPARTMENT TEXT NOT NULL
);

CREATE TABLE AISLES(
	AISLES_ID INTEGER PRIMARY KEY,
	AISELS TEXT NOT NULL
);
DROP TABLE AISLES;
CREATE TABLE PRODUCTS(
	PRODUCT_ID INTEGER PRIMARY KEY,
	PRODUCT_NAME TEXT NOT NULL,
	AISLES_ID INTEGER REFERENCES AISLES(AISLES_ID),
	DEPARTMENT_ID INTEGER REFERENCES DEPARTMENTS(DEPARTMENT_ID)
	);
SELECT column_name FROM information_schema.columns WHERE table_name = 'aisles';

CREATE TABLE ORDERS(
 ORDER_ID INTEGER PRIMARY KEY,
 USER_ID INTEGER NOT NULL,
 EVAL_SET TEXT NOT NULL,
 ORDER_NUMBER INTEGER,
 ORDER_DOW INTEGER,
 ORDER_HOUR_OF_DAY INTEGER,
 DAYS_SINCE_PRIOR_ORDER NUMERIC
);
CREATE TABLE ORDER_ITEM(
ORDER_ID INTEGER REFERENCES ORDERS(ORDER_ID),
PRODUCT_ID INTEGER REFERENCES PRODUCTS(PRODUCT_ID),
ADD_TO_CART_ORDER INTEGER,
REORDERED INTEGER,
PRIMARY KEY(ORDER_ID,PRODUCT_ID)

);

---importing dataset----

SELECT * FROM departments LIMIT 5;
SELECT COUNT(*) FROM departments;

COPY departments(department_id, department)
FROM 'C:/Instacart/departments.csv'
DELIMITER ','
CSV HEADER;

SELECT COUNT(*) FROM departments;

COPY aisles(aisle_id, aisle)
FROM 'C:/Instacart/aisles.csv'
DELIMITER ','
CSV HEADER;

COPY products(product_id, product_name, aisle_id, department_id)
FROM 'C:/Instacart/products.csv'
DELIMITER ','
CSV HEADER;

COPY orders(order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, days_since_prior_order)
FROM 'C:/Instacart/orders.csv'
DELIMITER ','
CSV HEADER;

COPY order_items(order_id, product_id, add_to_cart_order, reordered)
FROM 'C:/Instacart/order_products__train.csv'
DELIMITER ','
CSV HEADER;




DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS aisles CASCADE;

CREATE TABLE aisles (
    aisle_id   INTEGER PRIMARY KEY,
    aisle      TEXT NOT NULL
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    aisle_id        INTEGER REFERENCES aisles(aisle_id),
    department_id   INTEGER REFERENCES departments(department_id)
);


COPY aisles(aisle_id, aisle)
FROM 'C:/Instacart/aisles.csv'
DELIMITER ','
CSV HEADER;

COPY products(product_id, product_name, aisle_id, department_id)
FROM 'C:/Instacart/products.csv'
DELIMITER ','
CSV HEADER;


SELECT COUNT(*) FROM aisles;   -- expect 134
SELECT COUNT(*) FROM products; -- expect 49688


COPY orders(order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, days_since_prior_order)
FROM 'C:/Instacart/orders.csv'
DELIMITER ','
CSV HEADER;
SELECT COUNT(*) FROM orders;

COPY order_item(order_id, product_id, add_to_cart_order, reordered)
FROM 'C:/Instacart/order_products__train.csv'
DELIMITER ','
CSV HEADER;
SELECT COUNT(*) FROM order_item;




--data cleaning--
--checking null values--
SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL) AS null_user_id,
    COUNT(*) FILTER (WHERE order_dow IS NULL) AS null_dow,
    COUNT(*) FILTER (WHERE order_hour_of_day IS NULL) AS null_hour,
    COUNT(*) FILTER (WHERE days_since_prior_order IS NULL) AS null_days_since
FROM orders;

SELECT COUNT(*) 
FROM orders 
WHERE days_since_prior_order IS NULL;

SELECT COUNT(*) 
FROM orders 
WHERE order_number = 1;

--duplicates in product---
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

--orphan check--
SELECT oi.order_id
FROM order_item oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--invalid values--
SELECT COUNT(*) FILTER (WHERE add_to_cart_order <= 0) AS bad_cart_order,
       COUNT(*) FILTER (WHERE reordered NOT IN (0,1)) AS bad_reordered
FROM order_item;


CREATE OR REPLACE VIEW orders_clean AS
SELECT *
FROM orders
WHERE eval_set = 'train';

SELECT COUNT(*) FROM orders_clean; 

SELECT product_name FROM products ORDER BY random() LIMIT 20;

SELECT p.product_id
FROM products p
LEFT JOIN aisles a ON p.aisle_id = a.aisle_id
WHERE a.aisle_id IS NULL;



---KPI Queries---
--Average Basket Size--

SELECT ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM (
    SELECT order_id, COUNT(*) AS item_count
    FROM order_item
    GROUP BY order_id
) AS order_sizes;

--finding of large,small orders and median items--

SELECT
    MIN(item_count) AS smallest_order,
    MAX(item_count) AS largest_order,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY item_count) AS median_items
FROM (
    SELECT order_id, COUNT(*) AS item_count
    FROM order_item
    GROUP BY order_id
) AS order_sizes;

--Order timing pattern--
SELECT
    order_dow,
    COUNT(*) AS total_orders
FROM orders_clean
GROUP BY order_dow
ORDER BY order_dow;

--Top 10 most frequently ordered products--
SELECT p.product_name,
	   COUNT(*) AS times_ordered
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY times_ordered DESC
LIMIT 10;

--Reorder rate--
SELECT ROUND(100*SUM(reordered)/COUNT(*),2) AS reorder_order_rate
FROM order_item;

--Reorder Rate by product--
SELECT
    p.product_name,
    COUNT(*) AS total_orders,
    SUM(oi.reordered) AS total_reorders,
    ROUND(100.0 * SUM(oi.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
HAVING COUNT(*) >= 50   
ORDER BY reorder_rate_pct DESC
LIMIT 10;

--Customer Order Frequency--
SELECT
    ROUND(AVG(days_since_prior_order), 2) AS avg_days_between_orders
FROM orders_clean
WHERE days_since_prior_order IS NOT NULL;







-- 1. Basket size per order (Power BI can aggregate this itself)
CREATE OR REPLACE VIEW vw_order_basket_sizes AS
SELECT order_id, COUNT(*) AS item_count
FROM order_item
GROUP BY order_id;

-- 2. Order timing pattern
CREATE OR REPLACE VIEW vw_orders_by_dow AS
SELECT order_dow, COUNT(*) AS total_orders
FROM orders_clean
GROUP BY order_dow;

-- 3. Top products by volume
CREATE OR REPLACE VIEW vw_top_products AS
SELECT p.product_name, COUNT(*) AS times_ordered
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name;

-- 4. Reorder rate by product
CREATE OR REPLACE VIEW vw_reorder_rate_by_product AS
SELECT
    p.product_name,
    COUNT(*) AS total_orders,
    SUM(oi.reordered) AS total_reorders,
    ROUND(100.0 * SUM(oi.reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
HAVING COUNT(*) >= 50;

-- 5. Order cadence per customer (useful detail Power BI can aggregate/filter)
CREATE OR REPLACE VIEW vw_customer_order_cadence AS
SELECT order_id, user_id, days_since_prior_order
FROM orders_clean
WHERE days_since_prior_order IS NOT NULL;


SELECT table_name FROM information_schema.views WHERE table_schema = 'public';