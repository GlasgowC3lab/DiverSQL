WITH catalog_sales_prepped AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_quantity AS quantity,
          cs.cs_net_paid AS net_paid,
          'catalog' AS channel,
          d.d_year AS yr,
          d.d_month_seq AS month_seq
   FROM catalog_sales cs
   LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002 OR d.d_year IS NULL
),
store_sales_prepped AS (
   SELECT ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_quantity AS quantity,
          ss.ss_net_paid AS net_paid,
          'store' AS channel,
          d.d_year AS yr,
          d.d_month_seq AS month_seq
   FROM store_sales ss
   LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002 OR d.d_year IS NULL
),
web_sales_prepped AS (
   SELECT ws.ws_sold_date_sk AS date_sk,
          ws.ws_item_sk AS item_sk,
          ws.ws_quantity AS quantity,
          ws.ws_net_paid AS net_paid,
          'web' AS channel,
          d.d_year AS yr,
          d.d_month_seq AS month_seq
   FROM web_sales ws
   LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002 OR d.d_year IS NULL
),
all_sales AS (
   SELECT * FROM catalog_sales_prepped
   UNION ALL
   SELECT * FROM store_sales_prepped
   UNION ALL
   SELECT * FROM web_sales_prepped
),
monthly_raw AS (
   SELECT
      yr,
      month_seq,
      channel,
      item_sk,
      SUM(quantity) AS total_qty,
      SUM(net_paid) AS total_net,
      COUNT(*) AS txn_cnt
   FROM all_sales
   WHERE yr IS NOT NULL
   GROUP BY yr, month_seq, channel, item_sk
),
monthly_agg AS (
   SELECT
      mr.*,
      ROW_NUMBER() OVER (PARTITION BY yr, month_seq, channel ORDER BY total_net DESC) AS rn
   FROM monthly_raw mr
),
item_info AS (
   SELECT i_item_sk, i_item_id, i_product_name, i_brand, i_category, i_color
   FROM item
),
low_sales_items AS (
   SELECT DISTINCT item_sk
   FROM (
      SELECT cs.item_sk, cs.quantity
      FROM catalog_sales_prepped cs
      WHERE cs.quantity < 5
      UNION
      SELECT ss.item_sk, ss.quantity
      FROM store_sales_prepped ss
      WHERE ss.quantity < 5
      UNION
      SELECT ws.item_sk, ws.quantity
      FROM web_sales_prepped ws
      WHERE ws.quantity < 5
   )
)

SELECT
   ma.yr,
   ma.month_seq,
   ma.channel,
   ii.i_item_id,
   ii.i_product_name,
   ma.total_qty,
   ma.total_net,
   ma.txn_cnt,
   COALESCE((
       SELECT ROUND(AVG(mr2.total_net), 2)
       FROM monthly_raw mr2
       WHERE mr2.item_sk = ma.item_sk
         AND mr2.yr = ma.yr
         AND mr2.month_seq = ma.month_seq
   ), 0) AS avg_monthly_net_all_channels,
   CASE WHEN ma.rn <= 5 THEN 'Top5' ELSE 'Top10' END AS rank_group,
   CONCAT(ma.channel, '_', CAST(ma.month_seq AS VARCHAR), '_', CAST(ma.rn AS VARCHAR)) AS unique_key,
   CASE
     WHEN ii.i_brand IS NULL THEN 'MissingBrand'
     WHEN ii.i_category IS NULL THEN 'MissingCategory'
     ELSE 'OK'
   END AS data_quality_flag,
   (SELECT SUM(mr3.txn_cnt)
    FROM monthly_raw mr3
    WHERE mr3.item_sk = ma.item_sk) AS total_txn_all_months,
   (SELECT COUNT(*)
    FROM low_sales_items lsi
    WHERE lsi.item_sk = ma.item_sk) AS low_sales_months
FROM monthly_agg ma
LEFT JOIN item_info ii ON ii.i_item_sk = ma.item_sk
WHERE ma.rn <= 10
ORDER BY ma.channel, ma.yr, ma.month_seq, ma.rn
