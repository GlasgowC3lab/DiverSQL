WITH
  sampled_warehouse AS (
    SELECT *
    FROM warehouse TABLESAMPLE BERNOULLI (5)
  ),
  high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
  ),
  item_not_in_sales AS (
    SELECT i_item_sk
    FROM item
    EXCEPT
    SELECT ss_item_sk
    FROM store_sales
  ),
  store_sales_filtered AS (
    SELECT *
    FROM store_sales
    WHERE ss_item_sk NOT IN (SELECT i_item_sk FROM high_price_items)
  ),
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_ticket_number,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      i.i_brand,
      i.i_category,
      hd.hd_vehicle_count,
      ca.ca_state,
      s.s_store_name
    FROM store_sales_filtered ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
  ),
  web_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ws.ws_net_paid) AS web_net_paid,
      COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'CA'
      AND w.w_city = 'Seattle'
    GROUP BY ROLLUP (d.d_year, i.i_category)
  ),
  call_center_agg AS (
    SELECT
      d.d_year,
      COUNT(DISTINCT cc.cc_call_center_id) AS cc_cnt
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_gmt_offset > -5
      AND cc.cc_tax_percentage < 10
      AND cc.cc_country = 'United States'
      AND cc.cc_state = 'TX'
    GROUP BY d.d_year
  )
SELECT
  COALESCE(b.ca_state, 'ALL') AS state,
  COALESCE(b.d_year, -1) AS year,
  COALESCE(b.i_category, 'ALL') AS category,
  SUM(b.ss_net_paid) AS store_net_paid,
  SUM(b.ss_net_profit) AS store_net_profit,
  SUM(COALESCE(w.web_net_paid, 0)) AS web_net_paid,
  SUM(COALESCE(b.sr_return_amt, 0)) AS total_return_amount,
  COUNT(DISTINCT b.ss_ticket_number) AS store_transactions,
  MAX(cc.cc_cnt) AS call_center_count,
  latest.p_discount_active AS latest_promo_discount
FROM base b
LEFT JOIN web_agg w
  ON b.d_year = w.d_year
 AND b.i_category = w.i_category
LEFT JOIN call_center_agg cc
  ON b.d_year = cc.d_year
CROSS JOIN LATERAL (
  SELECT p.p_discount_active
  FROM promotion p
  WHERE p.p_promo_sk = b.ss_promo_sk
  ORDER BY p.p_start_date_sk DESC
  LIMIT 1
) AS latest
GROUP BY ROLLUP (b.ca_state, b.d_year, b.i_category, latest.p_discount_active)
HAVING SUM(b.ss_net_paid) > 0
ORDER BY store_net_paid DESC
LIMIT 100
