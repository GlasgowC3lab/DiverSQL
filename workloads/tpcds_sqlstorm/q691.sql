WITH
date_range AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
store_sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
),
web_sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
),
union_sales AS (
    SELECT * FROM store_sales_filtered
    UNION ALL
    SELECT * FROM web_sales_filtered
),
customer_agg AS (
    SELECT
        us.customer_sk,
        SUM(us.ext_sales_price) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(us.ext_sales_price) DESC) AS cust_rank
    FROM union_sales us
    GROUP BY us.customer_sk
),
item_margins AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        COALESCE(i.i_wholesale_cost, 0) AS wholesale_cost,
        CASE
            WHEN i.i_current_price = 0 THEN NULL
            ELSE (i.i_current_price - COALESCE(i.i_wholesale_cost,0)) / i.i_current_price
        END AS margin
    FROM item i
),
top_items_per_store AS (
    SELECT
        us.store_sk,
        us.channel,
        us.item_sk,
        SUM(us.ext_sales_price) AS item_revenue,
        ROW_NUMBER() OVER (PARTITION BY us.store_sk, us.channel ORDER BY SUM(us.ext_sales_price) DESC) AS item_rank
    FROM union_sales us
    GROUP BY us.store_sk, us.channel, us.item_sk
),
sales_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        us.store_sk AS store_id,
        us.channel,
        SUM(us.ext_sales_price) AS total_revenue,
        SUM(us.net_profit) AS total_profit,
        COUNT(DISTINCT us.customer_sk) AS unique_customers,
        COUNT(*) AS total_transactions,
        AVG(us.ext_sales_price) AS avg_revenue,
        approx_percentile(us.ext_sales_price, 0.5) AS median_revenue,
        SUM(CASE WHEN us.channel = 'store' THEN us.ext_sales_price ELSE -us.ext_sales_price END) AS revenue_balance
    FROM union_sales us
    JOIN date_range dr ON us.date_sk = dr.d_date_sk
    GROUP BY GROUPING SETS (
        (dr.d_year, dr.d_month_seq, us.store_sk, us.channel),
        (dr.d_year, dr.d_month_seq, us.channel)
    )
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    CASE WHEN sa.store_id IS NULL THEN 'WEB' ELSE CAST(sa.store_id AS VARCHAR) END AS location_id,
    COALESCE(st.s_store_name, 'WEB') AS location_name,
    COALESCE(concat_ws(', ', st.s_city, st.s_state), 'WEB') AS location_full,
    sa.channel,
    sa.total_revenue,
    sa.total_profit,
    sa.unique_customers,
    sa.total_transactions,
    sa.avg_revenue,
    sa.median_revenue,
    sa.revenue_balance,
    CASE WHEN sa.revenue_balance > 0 THEN 'POS' ELSE 'NEG' END AS revenue_sign,
    (SELECT ca.total_spent FROM customer_agg ca ORDER BY ca.total_spent DESC LIMIT 1) AS top_customer_spent,
    (SELECT AVG(im.margin)
     FROM item_margins im
     JOIN union_sales us2 ON us2.item_sk = im.i_item_sk
     WHERE us2.channel = sa.channel) AS avg_margin_by_channel,
    im.margin AS top_item_margin,
    im.i_product_name AS top_item_name
FROM sales_agg sa
LEFT JOIN store st ON sa.store_id = st.s_store_sk
LEFT JOIN LATERAL (
    SELECT t.item_sk AS top_item_sk
    FROM top_items_per_store t
    WHERE t.store_sk = sa.store_id
      AND t.channel = sa.channel
      AND t.item_rank = 1
) AS top_item ON TRUE
LEFT JOIN item_margins im ON im.i_item_sk = top_item.top_item_sk
ORDER BY sa.d_year, sa.d_month_seq, sa.total_revenue DESC
LIMIT 200
