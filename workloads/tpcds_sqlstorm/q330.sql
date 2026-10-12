WITH
store_sales_agg AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_net_profit AS net_profit,
        ss_customer_sk AS customer_sk
    FROM store_sales
),
catalog_sales_agg AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_net_profit AS net_profit,
        cs_bill_customer_sk AS customer_sk
    FROM catalog_sales
),
web_sales_agg AS (
    SELECT
        ws_sold_date_sk AS sold_date_sk,
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_net_profit AS net_profit,
        ws_bill_customer_sk AS customer_sk
    FROM web_sales
),
all_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
agg_sales AS (
    SELECT
        sold_date_sk,
        item_sk,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        SUM(net_profit) / NULLIF(SUM(quantity), 0) AS profit_per_unit,
        COUNT(DISTINCT customer_sk) AS distinct_customers
    FROM all_sales
    GROUP BY sold_date_sk, item_sk
),
sales_with_date AS (
    SELECT
        a.sold_date_sk,
        a.item_sk,
        a.total_quantity,
        a.total_net_profit,
        a.profit_per_unit,
        a.distinct_customers,
        d.d_year,
        d.d_month_seq,
        (d.d_month_seq % 12) + 1 AS month_of_year,
        d.d_date,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        i.i_color,
        i.i_size,
        i.i_units,
        i.i_class,
        i.i_manufact,
        COALESCE(i.i_color, 'UNKNOWN') AS color_desc,
        CONCAT(i.i_brand, '-', i.i_product_name) AS product_desc,
        SUBSTR(CONCAT(i.i_brand, '-', i.i_product_name), 1, 20) AS product_desc_short
    FROM agg_sales a
    JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON a.item_sk = i.i_item_sk
)

SELECT
    s.d_year,
    s.month_of_year,
    s.i_category,
    s.i_brand,
    s.product_desc,
    s.product_desc_short,
    s.total_quantity,
    s.total_net_profit,
    s.profit_per_unit,
    s.distinct_customers,
    (SELECT COUNT(*)
     FROM agg_sales a2
     WHERE a2.sold_date_sk = s.sold_date_sk
       AND a2.item_sk <> s.item_sk
       AND (a2.total_net_profit / NULLIF(a2.total_quantity, 0)) > s.profit_per_unit) AS higher_ppu_items_same_day,
    ROW_NUMBER() OVER (PARTITION BY s.d_year, s.month_of_year ORDER BY s.total_net_profit DESC) AS profit_rank_month,
    SUM(s.total_net_profit) OVER (PARTITION BY s.i_category ORDER BY s.d_year, s.month_of_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_category,
    s.total_net_profit - LAG(s.total_net_profit) OVER (PARTITION BY s.item_sk ORDER BY s.d_year, s.month_of_year) AS delta_profit_vs_prev_month,
    CASE
        WHEN s.i_size IS NULL THEN 'MISSING_SIZE'
        WHEN s.i_size LIKE '%XL%' THEN 'XL_SIZED'
        ELSE s.i_size
    END AS size_flag,
    reverse(s.i_brand) AS brand_rev,
    COALESCE(cc.cc_name, 'NO_CALL_CENTER') AS call_center_name,
    CASE WHEN s.total_quantity > 1000 THEN 'BIG' ELSE 'SMALL' END AS size_category
FROM sales_with_date s
FULL OUTER JOIN call_center cc ON cc.cc_call_center_sk = s.item_sk
WHERE s.d_year = 2001
  AND (s.i_category = 'Sports' OR s.i_category IS NULL)
  AND s.total_net_profit IS NOT NULL
ORDER BY s.d_year, s.month_of_year, profit_rank_month
LIMIT 100
