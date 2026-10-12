WITH
  catalog_agg AS (
    SELECT
      cs.cs_item_sk AS cs_item_sk,
      cs.cs_sold_date_sk AS cs_sold_date_sk,
      SUM(cs.cs_net_paid) AS catalog_net_paid,
      SUM(cs.cs_quantity) AS catalog_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk AS ws_item_sk,
      ws.ws_sold_date_sk AS ws_sold_date_sk,
      SUM(ws.ws_net_paid) AS web_net_paid,
      SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws_site.web_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
  ),
  full_sales AS (
    SELECT
      COALESCE(ca.cs_item_sk, wa.ws_item_sk)                AS item_sk,
      COALESCE(ca.cs_sold_date_sk, wa.ws_sold_date_sk)    AS sold_date_sk,
      ca.catalog_net_paid,
      wa.web_net_paid
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa
      ON ca.cs_item_sk = wa.ws_item_sk
     AND ca.cs_sold_date_sk = wa.ws_sold_date_sk
  ),
  returned_items AS (
    SELECT cr_item_sk AS item_sk FROM catalog_returns
    UNION
    SELECT wr_item_sk FROM web_returns
  ),
  filtered_sales AS (
    SELECT *
    FROM full_sales
    WHERE item_sk NOT IN (SELECT item_sk FROM returned_items)
  ),
  catalog_key_set AS (
    SELECT cs_item_sk AS item_sk FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450100
  )
SELECT
  fs.item_sk,
  fs.sold_date_sk,
  fs.catalog_net_paid,
  fs.web_net_paid,
  (COALESCE(fs.catalog_net_paid, 0) - COALESCE(fs.web_net_paid, 0)) AS net_diff
FROM filtered_sales fs
WHERE fs.item_sk IN (
  SELECT item_sk FROM filtered_sales
  EXCEPT
  SELECT item_sk FROM catalog_key_set
)
ORDER BY net_diff DESC
LIMIT 100
