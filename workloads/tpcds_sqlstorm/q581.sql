WITH store_sales_agg AS (
    SELECT ss_item_sk AS item_sk,
           ss_sold_date_sk AS date_sk,
           SUM(ss_net_profit) AS profit,
           SUM(ss_quantity) AS quantity
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
),
catalog_sales_agg AS (
    SELECT cs_item_sk AS item_sk,
           cs_sold_date_sk AS date_sk,
           SUM(cs_net_profit) AS profit,
           SUM(cs_quantity) AS quantity
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_sold_date_sk
),
web_sales_agg AS (
    SELECT ws_item_sk AS item_sk,
           ws_sold_date_sk AS date_sk,
           SUM(ws_net_profit) AS profit,
           SUM(ws_quantity) AS quantity
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
combined_sales AS (
    SELECT item_sk,
           date_sk,
           SUM(profit) AS total_profit,
           SUM(quantity) AS total_quantity
    FROM (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    ) AS u
    GROUP BY item_sk, date_sk
),
sales_monthly AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cs.total_profit) AS month_profit,
        SUM(cs.total_quantity) AS month_quantity,
        MAX(p.p_promo_name) AS promo_name,
        SUM(p.p_cost) AS promo_cost
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    JOIN item i ON cs.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_moy
),
promo_monthly AS (
    SELECT
        p.p_item_sk AS item_sk,
        d.d_year AS year,
        d.d_moy AS month,
        COUNT(*) AS promo_days,
        SUM(p.p_cost) AS promo_cost,
        MAX(p.p_promo_name) AS promo_name
    FROM promotion p
    JOIN date_dim d ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY p.p_item_sk, d.d_year, d.d_moy
),
full_data AS (
    SELECT
        COALESCE(s.item_sk, p.item_sk) AS item_sk,
        COALESCE(s.product_name, i.i_product_name) AS product_name,
        COALESCE(s.year, p.year) AS year,
        COALESCE(s.month, p.month) AS month,
        COALESCE(s.month_profit, 0) AS month_profit,
        COALESCE(s.month_quantity, 0) AS month_quantity,
        COALESCE(s.promo_name, p.promo_name, 'No Promo') AS promo_name,
        COALESCE(s.promo_cost, p.promo_cost, 0) AS promo_cost
    FROM sales_monthly s
    FULL OUTER JOIN promo_monthly p
        ON s.item_sk = p.item_sk
        AND s.year = p.year
        AND s.month = p.month
    LEFT JOIN item i ON COALESCE(s.item_sk, p.item_sk) = i.i_item_sk
)
SELECT
    fd.item_sk,
    fd.product_name,
    CONCAT(CAST(fd.year AS VARCHAR), '-', LPAD(CAST(fd.month AS VARCHAR), 2, '0')) AS year_month,
    fd.month_profit,
    fd.month_quantity,
    fd.promo_name,
    fd.promo_cost,
    ROUND(fd.month_profit / NULLIF(fd.month_quantity * i.i_current_price, 0), 4) AS profit_margin,
    RANK() OVER (PARTITION BY fd.year, fd.month ORDER BY fd.month_profit DESC) AS profit_rank,
    AVG(fd.month_profit) OVER (PARTITION BY fd.item_sk ORDER BY fd.year, fd.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m,
    (SELECT month_profit FROM full_data fd2 WHERE fd2.item_sk = fd.item_sk AND fd2.year = fd.year - 1 AND fd2.month = fd.month) AS yoy_month_profit,
    CASE
        WHEN fd.month_profit > 0 AND fd.promo_name <> 'No Promo' THEN 'Promo Boost'
        WHEN fd.month_profit > 0 THEN 'Profit'
        ELSE 'No Profit'
    END AS profit_status
FROM full_data fd
LEFT JOIN item i ON fd.item_sk = i.i_item_sk
WHERE fd.month_profit > 0 OR fd.promo_name <> 'No Promo'
ORDER BY fd.year, fd.month, profit_rank
LIMIT 100
