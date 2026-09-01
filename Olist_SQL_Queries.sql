-- Q1. Retrieve the total number of orders placed on the e-commerce platform?

SELECT COUNT(order_id) AS total_orders
FROM orders;


-- Q2. Calculate the total amount generated from product sales?

SELECT SUM(price) AS total_revenue
FROM order_items;


-- Q3. Determine the total number of unique customers?

SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;


-- Q4. Calculate the average amount spent per order on products?

SELECT AVG(order_total) AS average_order_amount
FROM (
    SELECT order_id, SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
) AS order_totals;


-- Q5. Determine the number of orders for each order status?

SELECT COUNT(order_id) AS total_orders, order_status
FROM orders
GROUP BY order_status;


-- Q6. Determine the total amount generated from product sales for each customer state?

SELECT c.customer_state, SUM(items.price) AS total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items items ON o.order_id = items.order_id
GROUP BY c.customer_state;


-- Q7. Determine the number of orders placed in each customer state and rank the states from highest to lowest based on total orders?

SELECT c.customer_state,
       COUNT(o.order_id) AS total_orders,
       RANK() OVER (ORDER BY COUNT(o.order_id) DESC) AS order_rank
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state;


-- Q8. Determine the average product price for each customer state and rank the states from highest to lowest based on average product price?

SELECT c.customer_state,
       AVG(items.price) AS avg_product_price,
       RANK() OVER (ORDER BY AVG(items.price) DESC) AS price_rank
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_items items 
    ON o.order_id = items.order_id
GROUP BY c.customer_state;


-- Q9. Identify the top 10 product categories by total amount generated from product sales.

WITH product_cat AS (
    SELECT p.product_category_name, prod_english.product_category_name_english, SUM(items.price) AS total_amount
    FROM products p
    JOIN order_items items ON p.product_id = items.product_id
    JOIN product_category_name_translation prod_english ON prod_english.product_category_name = p.product_category_name
    GROUP BY p.product_category_name, prod_english.product_category_name_english
)
SELECT product_category_name, product_category_name_english, total_amount
FROM product_cat
ORDER BY total_amount DESC
LIMIT 10;


-- Q10. Identify the top 10 customers by total amount spent on products.

WITH total_order AS (
    SELECT c.customer_unique_id, SUM(items.price) AS total_amount
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items items ON o.order_id = items.order_id
    GROUP BY c.customer_unique_id
)
SELECT customer_unique_id, total_amount
FROM total_order
ORDER BY total_amount DESC
LIMIT 10;


-- Q11. Identify the top 10 product categories by the number of products sold.

WITH product_cat AS (
    SELECT p.product_category_name, prod_english.product_category_name_english, COUNT(items.product_id) AS total_products
    FROM products p
    JOIN order_items items ON p.product_id = items.product_id
    LEFT JOIN product_category_name_translation prod_english ON p.product_category_name = prod_english.product_category_name
    GROUP BY p.product_category_name, prod_english.product_category_name_english
)
SELECT product_category_name_english, total_products
FROM product_cat
ORDER BY total_products DESC
LIMIT 10;


-- Q12. Calculate the percentage of delivered orders that were delivered late.

SELECT
SUM(CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN 1 ELSE 0 END) AS late_orders,
COUNT(order_delivered_customer_date) AS total_delivered_orders,
ROUND(SUM(CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN 1 ELSE 0 END) / COUNT(order_delivered_customer_date) * 100, 2) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- Q13. Identify the product categories with more than 5,000 products sold.

SELECT 
    p.product_category_name,
    pcnt.product_category_name_english,
    COUNT(items.product_id) AS total_products
FROM order_items items
JOIN products p 
    ON items.product_id = p.product_id
JOIN product_category_name_translation pcnt 
    ON p.product_category_name = pcnt.product_category_name
GROUP BY 
    p.product_category_name,
    pcnt.product_category_name_english
HAVING total_products > 5000;


-- Q14. Identify products whose total freight cost exceeds 300% of their total product sales value.

SELECT pcnt.product_category_name_english,
       p.product_id,
       SUM(items.price) AS total_price,
       SUM(items.freight_value) AS total_shipping,
       (SUM(items.freight_value) / SUM(items.price)) * 100 AS freight_percentage
FROM order_items items
JOIN products p 
    ON items.product_id = p.product_id
JOIN product_category_name_translation pcnt 
    ON pcnt.product_category_name = p.product_category_name
GROUP BY p.product_id, pcnt.product_category_name_english
HAVING freight_percentage > 300
ORDER BY freight_percentage DESC;


-- Q15. For each product category, calculate the total revenue including both product price and freight charges, and rank the categories from highest to lowest total revenue.

WITH total_sales_revenue AS (
    SELECT 
        p.product_category_name,
        pcnt.product_category_name_english,
        SUM(price + freight_value) AS total_revenue
    FROM order_items items
    JOIN products p 
        ON items.product_id = p.product_id
    JOIN product_category_name_translation pcnt 
        ON p.product_category_name = pcnt.product_category_name
    GROUP BY 
        p.product_category_name,
        pcnt.product_category_name_english
)
SELECT 
    product_category_name,
    product_category_name_english,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS total_revenue_rank
FROM total_sales_revenue;


-- Q16. Determine the average freight cost for each customer state.

SELECT c.customer_state,
       AVG(items.freight_value) AS avg_freight
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_items items 
    ON o.order_id = items.order_id
GROUP BY c.customer_state;


-- Q17. Determine the percentage of orders for each order status.

SELECT order_status,
       COUNT(order_id) AS total_orders,
       (COUNT(order_id) / SUM(COUNT(order_id)) OVER ()) * 100 AS order_percentage
FROM orders
GROUP BY order_status;


-- Q18. Determine the number and percentage of repeat customers who placed more than one order.

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    COUNT(*) AS repeat_customers,
    ROUND(
        (COUNT(*) / (SELECT COUNT(*) FROM customer_orders)) * 100, 2
    ) AS repeat_customer_percentage
FROM customer_orders
WHERE total_orders > 1;


-- Q19. Calculate the total product sales amount for each month and rank the months from highest to lowest based on total sales.

SELECT 
    YEAR(o.order_purchase_timestamp) AS year,
    MONTHNAME(o.order_purchase_timestamp) AS month,
    MONTH(o.order_purchase_timestamp) AS month_number,
    SUM(items.price) AS total_sales,
    RANK() OVER (ORDER BY SUM(items.price) DESC) AS sales_rank
FROM orders o
JOIN order_items items 
    ON o.order_id = items.order_id
GROUP BY 
    YEAR(o.order_purchase_timestamp),
    MONTHNAME(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY 
    year, 
    month_number;
