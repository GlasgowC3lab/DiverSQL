WITH store_product AS (
   SELECT 
      ss.ss_item_sk AS item_sk,
      SUM(ss.ss_net_profit) AS store_total_profit,
      SUM(ss.ss_quantity) AS store_total_qty,
      AVG(ss.ss_sales_price) AS store_avg_price
   FROM store_sales ss
   GROUP BY ss.ss_item_sk
),
web_product AS (
   SELECT 
      ws.ws_item_sk AS item_sk,
      SUM(ws.ws_net_profit) AS web_total_profit,
      SUM(ws.ws_quantity) AS web_total_qty,
      AVG(ws.ws_sales_price) AS web_avg_price
   FROM web_sales ws
   GROUP BY ws.ws_item_sk
),
product_comparison AS (
   SELECT 
      COALESCE(sp.item_sk, wp.item_sk) AS item_sk,
      sp.store_total_profit,
      sp.store_total_qty,
      sp.store_avg_price,
      wp.web_total_profit,
      wp.web_total_qty,
      wp.web_avg_price,
      (sp.store_total_profit - wp.web_total_profit) AS profit_diff,
      (sp.store_avg_price - wp.web_avg_price) AS price_diff
   FROM store_product sp
   FULL OUTER JOIN web_product wp ON sp.item_sk = wp.item_sk
)
SELECT 
   pc.item_sk,
   pc.store_total_profit,
   pc.web_total_profit,
   pc.profit_diff,
   pc.store_avg_price,
   pc.web_avg_price,
   pc.price_diff,
   DENSE_RANK() OVER (ORDER BY pc.profit_diff DESC) AS profit_diff_rank,
   CASE 
      WHEN pc.profit_diff > 10000 THEN 'HugeDiff'
      WHEN pc.profit_diff > 5000 THEN 'LargeDiff'
      WHEN pc.profit_diff > 0 THEN 'PositiveDiff'
      ELSE 'NegativeDiff'
   END AS profit_diff_category,
   top_c.c_customer_id AS top_store_customer_id,
   top_c.c_first_name AS top_store_customer_first_name,
   top_c.c_last_name AS top_store_customer_last_name,
   top_c.cd_gender AS top_customer_gender
FROM product_comparison pc
LEFT JOIN LATERAL (
   SELECT 
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE ss.ss_item_sk = pc.item_sk
   ORDER BY ss.ss_net_profit DESC
   LIMIT 1
) AS top_c ON TRUE
WHERE pc.profit_diff IS NOT NULL
ORDER BY profit_diff_rank
LIMIT 25
