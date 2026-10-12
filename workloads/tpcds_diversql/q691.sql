WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        d.d_year,
        w.w_city,
        w.w_state,
        p.p_promo_name,
        cp.cp_description
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)exciting')
      AND p.p_promo_name LIKE '%Discount%'
),
returned_orders AS (
    SELECT DISTINCT wr.wr_order_number AS order_number
    FROM web_returns wr
),
non_returned_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT order_number FROM returned_orders
),
filtered_sales AS (
    SELECT s.*
    FROM sales s
    JOIN non_returned_orders n ON s.cs_order_number = n.order_number
    WHERE s.d_year = (SELECT max(d_year) FROM date_dim)
),
aggregated AS (
    SELECT
        CONCAT(fs.w_city, ', ', fs.w_state) AS location,
        SUM(fs.cs_net_profit) AS sum_profit,
        SUM(fs.cs_net_paid)   AS total_net_paid,
        COUNT(*)               AS orders_count,
        regexp_extract(fs.cp_description, '([A-Za-z]+)', 1) AS first_word,
        fs.cs_order_number,
        COALESCE(
            (SELECT SUM(wr.wr_return_amt)
             FROM web_returns wr
             WHERE wr.wr_order_number = fs.cs_order_number),
            0
        ) AS total_return_amount
    FROM filtered_sales fs
    GROUP BY
        fs.w_city,
        fs.w_state,
        fs.cp_description,
        fs.cs_order_number
)
SELECT
    a.location,
    CASE WHEN a.sum_profit > (SELECT avg(cs_net_profit) FROM catalog_sales)
         THEN 'Above Avg'
         ELSE 'Below Avg'
    END AS profit_category,
    a.first_word,
    a.orders_count,
    a.total_net_paid,
    LAG(a.total_net_paid) OVER (PARTITION BY a.location ORDER BY a.first_word) AS prev_word_net_paid,
    a.total_return_amount
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
