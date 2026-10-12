WITH
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_quantity AS quantity,
      ws.ws_ext_sales_price AS ext_sales_price,
      ws.ws_net_profit AS net_profit,
      ws.ws_promo_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_site_sk,
      c.c_customer_sk,
      ca.ca_state,
      ca.ca_zip,
      p.p_discount_active,
      w.w_country,
      w.w_city,
      t.t_hour
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE s.web_country = 'United States'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_sales_price > 1000
  ),
  sr_base AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_return_quantity AS quantity,
      sr.sr_return_amt AS ext_sales_price,
      sr.sr_net_loss AS net_profit,
      c.c_customer_sk,
      ca.ca_state,
      ca.ca_zip,
      t.t_hour,
      sr.sr_return_tax
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND sr.sr_return_tax > 10
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_amt > 500
  )
SELECT
  agg.source,
  agg.region,
  agg.total_quantity,
  agg.total_sales,
  agg.avg_profit,
  agg.profit_category,
  agg.promo_active_flag,
  agg.row_num,
  (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost,
  cg.grp
FROM (
  SELECT
    'WebSales' AS source,
    w.w_city AS region,
    SUM(ws.quantity) AS total_quantity,
    SUM(ws.ext_sales_price) AS total_sales,
    AVG(ws.net_profit) AS avg_profit,
    CASE WHEN AVG(ws.net_profit) > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    MAX(p.p_discount_active) AS promo_active_flag,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ext_sales_price) DESC) AS row_num
  FROM ws_base ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr
    WHERE sr.sr_customer_sk = ws.c_customer_sk
      AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
  )
  GROUP BY w.w_city

  UNION DISTINCT

  SELECT
    'StoreReturns' AS source,
    w.w_city AS region,
    SUM(sr.quantity) AS total_quantity,
    SUM(sr.ext_sales_price) AS total_sales,
    AVG(sr.net_profit) * -1 AS avg_profit,
    CASE WHEN AVG(sr.net_profit) * -1 > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    MAX(p.p_discount_active) AS promo_active_flag,
    ROW_NUMBER() OVER (ORDER BY SUM(sr.ext_sales_price) DESC) AS row_num
  FROM sr_base sr
  JOIN promotion p ON 1 = 1               -- cross join to bring promotion columns
  JOIN warehouse w ON 1 = 1                -- cross join to bring warehouse columns
  WHERE NOT EXISTS (
    SELECT 1 FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = sr.c_customer_sk
      AND ws.ws_sold_date_sk = sr.sr_returned_date_sk
  )
  GROUP BY w.w_city
) agg
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) cg
ORDER BY agg.total_sales DESC
LIMIT 100
