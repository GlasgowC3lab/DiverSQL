WITH sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS store_sk,
           NULL AS web_page_sk,
           NULL AS call_center_sk,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           ss_customer_sk AS cust_sk,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           NULL,
           NULL,
           NULL,
           ws_quantity,
           ws_net_profit,
           ws_net_paid,
           ws_bill_customer_sk,
           'web'
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           NULL,
           NULL,
           cs_call_center_sk,
           cs_quantity,
           cs_net_profit,
           cs_net_paid,
           cs_bill_customer_sk,
           'catalog'
    FROM catalog_sales
),
agg_sales AS (
    SELECT d.d_year,
           d.d_moy AS month_,
           s.channel,
           i.i_category,
           i.i_brand,
           SUM(s.quantity) AS total_quantity,
           SUM(s.net_profit) AS total_profit,
           SUM(s.net_paid) AS total_paid,
           approx_distinct(s.cust_sk) AS approx_customers
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN web_page wp ON s.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_category IS NOT NULL
    GROUP BY d.d_year, d.d_moy, s.channel, i.i_category, i.i_brand
)
SELECT a.d_year,
       a.month_,
       a.channel,
       a.i_category,
       a.i_brand,
       a.total_quantity,
       a.total_profit,
       a.total_paid,
       a.approx_customers,
       ROUND(a.total_profit / NULLIF(a.total_quantity, 0), 2) AS profit_per_item,
       ROUND(AVG(CASE WHEN a.total_profit > 0 THEN a.total_profit END) OVER (PARTITION BY a.channel, a.i_category, a.i_brand), 2) AS avg_positive_profit,
       approx_percentile(a.total_profit, 0.5) OVER (PARTITION BY a.channel, a.i_category, a.i_brand) AS median_profit,
       LAG(a.total_profit) OVER (PARTITION BY a.channel, a.i_category, a.i_brand ORDER BY a.d_year, a.month_) AS prev_month_profit,
       ROUND((a.total_profit - LAG(a.total_profit) OVER (PARTITION BY a.channel, a.i_category, a.i_brand ORDER BY a.d_year, a.month_)) / NULLIF(LAG(a.total_profit) OVER (PARTITION BY a.channel, a.i_category, a.i_brand ORDER BY a.d_year, a.month_), 0) * 100, 2) AS profit_growth_pct,
       ROUND(AVG(a.total_profit) OVER (PARTITION BY a.channel, a.i_category, a.i_brand ORDER BY a.d_year, a.month_ ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m_profit,
       RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank_year
FROM agg_sales a
ORDER BY a.d_year, a.month_, a.channel, a.total_profit DESC
