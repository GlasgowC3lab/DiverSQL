WITH sales AS (
  SELECT
    i.i_item_id,
    p.p_promo_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_returns
  FROM store_sales ss
  JOIN time_dim td                  ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i                       ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p                  ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd   ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca         ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr       ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN web_sales ws                ON ws.ws_item_sk = i.i_item_sk
                                   AND ws.ws_sold_time_sk = td.t_time_sk
  JOIN warehouse w                 ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE td.t_hour BETWEEN 8 AND 17
    AND i.i_current_price > 100
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 60000
    AND ca.ca_state = 'CA'
    AND ss.ss_quantity > 2
  GROUP BY GROUPING SETS (
    (i.i_item_id, p.p_promo_id),
    (i.i_item_id),
    (p.p_promo_id),
    ()
  )
)
SELECT
  i_item_id,
  p_promo_id,
  total_sales,
  total_returns,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
  CASE WHEN total_sales > 5000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales
WHERE total_sales IS NOT NULL
UNION DISTINCT
SELECT
  i_item_id,
  p_promo_id,
  total_sales,
  total_returns,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
  CASE WHEN total_sales > 5000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales
WHERE total_returns > 0
ORDER BY total_sales DESC
LIMIT 100
