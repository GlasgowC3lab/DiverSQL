WITH
  inv_agg AS (
    SELECT
      inv.inv_warehouse_sk AS inv_warehouse_sk,
      inv.inv_date_sk      AS inv_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk, inv.inv_date_sk
  ),
  sales_agg AS (
    SELECT
      ss.ss_sold_date_sk  AS ss_sold_date_sk,
      ss.ss_sold_time_sk  AS ss_sold_time_sk,
      ss.ss_cdemo_sk      AS ss_cdemo_sk,
      ss.ss_hdemo_sk      AS ss_hdemo_sk,
      ss.ss_addr_sk       AS ss_addr_sk,
      ss.ss_store_sk      AS ss_store_sk,
      ss.ss_promo_sk      AS ss_promo_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit)       AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    GROUP BY GROUPING SETS (
      (ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_cdemo_sk, ss.ss_hdemo_sk, ss.ss_addr_sk, ss.ss_store_sk, ss.ss_promo_sk),
      (ss.ss_sold_date_sk, ss.ss_store_sk),
      (ss.ss_promo_sk),
      ()
    )
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY sa.total_profit DESC)                AS row_num,
  d.d_date                                                         AS sale_date,
  s.s_store_name                                                   AS store_name,
  s.s_state                                                        AS store_state,
  cd.cd_credit_rating                                              AS credit_rating,
  hd.hd_vehicle_count                                             AS vehicle_count,
  sa.total_sales                                                   AS total_sales,
  sa.total_profit                                                  AS total_profit,
  sa.orders                                                        AS order_cnt,
  p.p_promo_name                                                   AS promo_name,
  w.w_warehouse_name                                               AS warehouse_name,
  ia.total_qty_on_hand                                             AS qty_on_hand,
  wr.wr_return_amt                                                AS return_amount,
  r.r_reason_desc                                                  AS return_reason,
  wp.wp_url                                                        AS web_page_url,
  cc.cc_name                                                       AS call_center_name,
  cat.cp_type                                                      AS catalog_type,
  ws.web_name                                                      AS web_site_name,
  t.t_hour                                                         AS sale_hour,
  t_ret.t_hour                                                     AS return_hour
FROM sales_agg sa
LEFT JOIN date_dim d          ON sa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t          ON sa.ss_sold_time_sk = t.t_time_sk
LEFT JOIN customer_demographics cd ON sa.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON sa.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca ON sa.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store s             ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p         ON sa.ss_promo_sk = p.p_promo_sk
LEFT JOIN inv_agg ia          ON ia.inv_date_sk = d.d_date_sk
LEFT JOIN warehouse w         ON ia.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr     ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN time_dim t_ret      ON wr.wr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN reason r           ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp        ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN call_center cc     ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN catalog_page cat   ON cat.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_site ws        ON ws.web_open_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001                     AND
  s.s_state = 'CA'                    AND
  cd.cd_credit_rating = 'Good'        AND
  hd.hd_vehicle_count >= 1           AND
  p.p_discount_active = 'Y'           AND
  w.w_county = 'Williamson County'    AND
  cat.cp_type = 'monthly'             AND
  cc.cc_name LIKE '%Center%'
ORDER BY total_profit DESC
LIMIT 100
