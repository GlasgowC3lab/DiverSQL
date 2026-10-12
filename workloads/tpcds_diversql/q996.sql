WITH base AS (
  SELECT
    d_sold.d_year AS d_year,
    i.i_category AS i_category,
    sm.sm_type AS sm_type,
    cs.cs_net_paid AS cs_net_paid,
    ws.ws_net_paid AS ws_net_paid,
    ss.ss_net_paid AS ss_net_paid,
    -- scalar subquery: total rows in catalog_sales (same for every row)
    (SELECT count(*) FROM catalog_sales) AS total_catalog_rows,
    -- LATERAL subquery: total promotion cost for the current item
    pl.promo_total_cost
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  -- store_sales
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
  JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
  JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
  -- store_returns
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
  JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
  -- web_sales
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
  JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
  JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
  JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
  JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  -- LATERAL subquery for promotion cost per item
  LEFT JOIN LATERAL (
    SELECT sum(p2.p_cost) AS promo_total_cost
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) pl ON TRUE
  WHERE EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c_bill.c_customer_sk
          AND sr2.sr_net_loss > 1000
      )
),
agg AS (
  SELECT
    d_year,
    i_category,
    sm_type,
    SUM(cs_net_paid) AS catalog_net_paid,
    SUM(ws_net_paid) AS web_net_paid,
    SUM(ss_net_paid) AS store_net_paid,
    SUM(promo_total_cost) AS promo_cost_total,
    MAX(total_catalog_rows) AS total_catalog_rows
  FROM base
  GROUP BY d_year, i_category, sm_type
  HAVING SUM(cs_net_paid) > 1000
),
final AS (
  SELECT
    d_year,
    i_category,
    sm_type,
    catalog_net_paid,
    web_net_paid,
    store_net_paid,
    promo_cost_total,
    total_catalog_rows,
    SUM(catalog_net_paid) OVER (
        PARTITION BY i_category
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_catalog_net_paid
  FROM agg
)
SELECT
  d_year,
  i_category,
  sm_type,
  catalog_net_paid,
  web_net_paid,
  store_net_paid,
  promo_cost_total,
  total_catalog_rows,
  running_catalog_net_paid
FROM final
UNION DISTINCT
SELECT
  d_year,
  i_category,
  sm_type,
  catalog_net_paid * 0.9,
  web_net_paid * 0.9,
  store_net_paid * 0.9,
  promo_cost_total * 0.9,
  total_catalog_rows,
  running_catalog_net_paid * 0.9
FROM final
WHERE d_year BETWEEN 1997 AND 1998
ORDER BY catalog_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
