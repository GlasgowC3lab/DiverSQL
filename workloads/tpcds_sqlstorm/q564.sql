WITH raw_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_quantity AS qty,
           cs.cs_net_paid_inc_tax AS sales,
           cs.cs_net_profit AS profit,
           cs.cs_ext_discount_amt AS discount,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_item_sk,
           ss.ss_sold_date_sk,
           ss.ss_quantity,
           ss.ss_net_paid_inc_tax,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           ws.ws_quantity,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           'web'
    FROM web_sales ws
),
agg AS (
    SELECT item_sk,
           date_sk,
           SUM(qty) AS total_qty,
           SUM(sales) AS total_sales,
           SUM(profit) AS total_profit,
           SUM(discount) AS total_discount,
           COUNT_IF(channel = 'catalog') AS catalog_cnt,
           COUNT_IF(channel = 'store') AS store_cnt,
           COUNT_IF(channel = 'web') AS web_cnt,
           SUM(CASE WHEN channel = 'catalog' THEN qty ELSE 0 END) AS catalog_qty,
           SUM(CASE WHEN channel = 'store' THEN qty ELSE 0 END) AS store_qty,
           SUM(CASE WHEN channel = 'web' THEN qty ELSE 0 END) AS web_qty,
           SUM(CASE WHEN channel = 'catalog' THEN sales ELSE 0 END) AS catalog_sales,
           SUM(CASE WHEN channel = 'store' THEN sales ELSE 0 END) AS store_sales,
           SUM(CASE WHEN channel = 'web' THEN sales ELSE 0 END) AS web_sales
    FROM raw_sales
    GROUP BY item_sk, date_sk
),
agg_date AS (
    SELECT agg.*,
           d.d_date,
           d.d_year,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY total_sales DESC) AS sales_rank_year
    FROM agg
    JOIN date_dim d ON agg.date_sk = d.d_date_sk
)
SELECT agg_date.d_date,
       i.i_item_id,
       i.i_product_name,
       agg_date.total_qty,
       agg_date.total_sales,
       agg_date.total_profit,
       agg_date.total_discount,
       agg_date.catalog_qty,
       agg_date.store_qty,
       agg_date.web_qty,
       agg_date.catalog_sales,
       agg_date.store_sales,
       agg_date.web_sales,
       (agg_date.total_sales - agg_date.total_discount) / NULLIF(agg_date.total_qty, 0) AS avg_price_after_discount,
       (agg_date.total_profit / NULLIF(agg_date.total_sales, 0)) * 100 AS profit_margin_pct,
       agg_date.sales_rank_year,
       agg_date.catalog_cnt,
       agg_date.store_cnt,
       agg_date.web_cnt
FROM agg_date
JOIN item i ON agg_date.item_sk = i.i_item_sk
WHERE agg_date.d_year BETWEEN 1999 AND 2002
ORDER BY agg_date.d_year, agg_date.total_sales DESC
LIMIT 100
