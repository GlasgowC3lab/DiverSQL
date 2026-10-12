WITH store_part AS (
  SELECT
    ss.ss_ticket_number AS order_number,
    ss.ss_net_paid AS sales_amount,
    s.s_market_desc AS market_desc,
    CAST('store' AS VARCHAR) AS source
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE s.s_market_id = 5
    AND ss.ss_sold_date_sk BETWEEN 2450900 AND 2450905
),
catalog_part AS (
  SELECT
    cs.cs_order_number AS order_number,
    cs.cs_net_paid AS sales_amount,
    sm.sm_ship_mode_id AS market_desc,
    CAST('catalog' AS VARCHAR) AS source
  FROM catalog_sales cs
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE sm.sm_carrier = 'CarrierX'
    AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2450905
)
SELECT
  combined.order_number,
  combined.sales_amount,
  combined.market_desc,
  combined.source
FROM (
  SELECT * FROM store_part
  UNION ALL
  SELECT * FROM catalog_part
) AS combined
WHERE combined.order_number NOT IN (
  SELECT sr_ticket_number FROM store_returns
)
ORDER BY combined.sales_amount DESC, combined.order_number
LIMIT 100
