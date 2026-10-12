WITH store_sales_agg AS (
  SELECT ca.ca_state AS state,
         ss.ss_item_sk AS item_sk,
         SUM(ss.ss_net_profit) AS store_net_profit
  FROM store_sales ss
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca.ca_state, ss.ss_item_sk
),
store_returns_agg AS (
  SELECT ca.ca_state AS state,
         sr.sr_item_sk AS item_sk,
         SUM(sr.sr_net_loss) AS store_net_loss
  FROM store_returns sr
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca.ca_state, sr.sr_item_sk
),
catalog_returns_agg AS (
  SELECT ca.ca_state AS state,
         cr.cr_item_sk AS item_sk,
         SUM(cr.cr_net_loss) AS catalog_net_loss
  FROM catalog_returns cr
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_type = 'monthly'
    AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca.ca_state, cr.cr_item_sk
),
web_sales_agg AS (
  SELECT ca.ca_state AS state,
         ws.ws_item_sk AS item_sk,
         SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca.ca_state, ws.ws_item_sk
)
SELECT state,
       item_sk,
       (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) - COALESCE(store_net_loss, 0) - COALESCE(catalog_net_loss, 0)) AS total_net_profit,
       RANK() OVER (PARTITION BY state ORDER BY (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) - COALESCE(store_net_loss, 0) - COALESCE(catalog_net_loss, 0)) DESC) AS profit_rank
FROM (
  SELECT * FROM store_sales_agg
  FULL OUTER JOIN store_returns_agg USING (state, item_sk)
  FULL OUTER JOIN catalog_returns_agg USING (state, item_sk)
  FULL OUTER JOIN web_sales_agg USING (state, item_sk)
) t
WHERE (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) - COALESCE(store_net_loss, 0) - COALESCE(catalog_net_loss, 0)) > 0
ORDER BY state, profit_rank
LIMIT 100
