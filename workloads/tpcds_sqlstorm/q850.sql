WITH sales_union AS (
    SELECT 'store' AS channel,
           ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS location_sk,
           ss_customer_sk AS customer_sk,
           ss_promo_sk AS promo_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT 'catalog' AS channel,
           cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS location_sk,
           cs_bill_customer_sk AS customer_sk,
           cs_promo_sk AS promo_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT 'web' AS channel,
           ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_web_page_sk AS location_sk,
           ws_bill_customer_sk AS customer_sk,
           ws_promo_sk AS promo_sk,
           ws_quantity AS quantity,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit
    FROM web_sales
),
joined AS (
    SELECT su.channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_category,
           i.i_brand,
           COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS location_name,
           su.quantity,
           su.net_paid,
           su.net_profit
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN store st ON su.channel = 'store' AND su.location_sk = st.s_store_sk
    LEFT JOIN call_center cc ON su.channel = 'catalog' AND su.location_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON su.channel = 'web' AND su.location_sk = wp.wp_web_page_sk
),
agg AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           i_brand,
           channel,
           location_name,
           SUM(quantity) AS total_quantity,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit,
           ROUND(100.0 * SUM(net_profit) / NULLIF(SUM(net_paid), 0), 2) AS profit_pct,
           ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY SUM(net_profit) DESC) AS profit_rank
    FROM joined
    GROUP BY d_year, d_quarter_seq, i_category, i_brand, channel, location_name
    HAVING SUM(net_paid) > 50000
)
SELECT *
FROM agg
ORDER BY d_year, i_category, profit_rank
LIMIT 200
