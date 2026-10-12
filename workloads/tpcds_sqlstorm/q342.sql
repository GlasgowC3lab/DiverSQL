WITH date_hierarchy AS (
    SELECT d_date_sk, d_year
    FROM date_dim
),
sales_union AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           NULL AS call_center_sk,
           ss.ss_store_sk AS store_sk,
           NULL AS web_site_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_discount_amt AS discount,
           ss.ss_ext_tax AS tax,
           'store' AS channel
    FROM store_sales ss

    UNION ALL

    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_call_center_sk,
           NULL,
           NULL,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_ext_discount_amt,
           cs.cs_ext_tax,
           'catalog' AS channel
    FROM catalog_sales cs

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           NULL,
           NULL,
           ws.ws_web_site_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_ext_tax,
           'web' AS channel
    FROM web_sales ws
),
sales_enriched AS (
    SELECT su.*,
           i.i_category,
           i.i_category_id,
           i.i_brand,
           i.i_brand_id,
           d.d_year,
           s.s_store_name,
           cc.cc_name AS call_center_name,
           wsi.web_name AS web_site_name
    FROM sales_union su
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN date_hierarchy d ON su.date_sk = d.d_date_sk
    LEFT JOIN store s ON su.store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON su.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_site wsi ON su.web_site_sk = wsi.web_site_sk
),
category_year_metrics AS (
    SELECT channel,
           i_category,
           d_year,
           SUM(net_paid) AS total_sales,
           SUM(net_profit) AS total_profit,
           SUM(discount) AS total_discount,
           SUM(tax) AS total_tax,
           COUNT(DISTINCT item_sk) AS distinct_items,
           COUNT(*) AS total_transactions
    FROM sales_enriched
    GROUP BY channel, i_category, d_year
),
category_ranking AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY total_profit DESC) AS profit_rank,
           LAG(total_profit) OVER (PARTITION BY channel, i_category ORDER BY d_year) AS prev_year_profit
    FROM category_year_metrics
)
SELECT channel,
       i_category,
       d_year,
       total_sales,
       total_profit,
       total_discount,
       total_tax,
       distinct_items,
       total_transactions,
       profit_rank,
       CASE 
           WHEN prev_year_profit IS NULL OR prev_year_profit = 0 THEN NULL
           ELSE (total_profit - prev_year_profit) / prev_year_profit
       END AS yoy_profit_growth
FROM category_ranking
WHERE profit_rank <= 5
ORDER BY channel, d_year DESC, profit_rank
