WITH
  -- Pre‑aggregate catalog sales to reduce row‑level detail
  cs_agg AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_order_number,
      SUM(cs_net_paid)               AS total_net_paid,
      COUNT(*)                       AS cnt_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY
      cs_item_sk,
      cs_sold_date_sk,
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_order_number
  ),
  -- Customer keys that appear in both catalog and web sales (INTERSECT)
  customer_sales_ids AS (
    SELECT DISTINCT cs_bill_customer_sk AS customer_sk FROM catalog_sales
  ),
  customer_web_ids AS (
    SELECT DISTINCT ws_bill_customer_sk AS customer_sk FROM web_sales
  ),
  customer_intersect AS (
    SELECT customer_sk FROM customer_sales_ids
    INTERSECT
    SELECT customer_sk FROM customer_web_ids
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY SUM(cs_agg.total_net_paid) DESC)               AS row_num,
  d_sold.d_year,
  c.c_customer_id,
  cc.cc_name,
  w.w_warehouse_name,
  p.p_promo_name,
  SUM(cs_agg.total_net_paid)                                                  AS sum_total_net_paid,
  COUNT(DISTINCT cs_agg.cs_item_sk)                                          AS distinct_items_sold,
  COALESCE(SUM(cr.cr_return_amount), 0)                                      AS total_return_amount,
  COALESCE(SUM(ws.ws_net_paid), 0)                                           AS total_web_sales_net_paid,
  (SELECT MAX(ib_upper_bound) FROM income_band)                             AS max_income_upper_bound
FROM cs_agg
JOIN date_dim d_sold               ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer c                     ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc                 ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w                    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p                    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd      ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr       ON cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws              ON ws.ws_bill_customer_sk = c.c_customer_sk
                                    AND ws.ws_sold_date_sk = cs_agg.cs_sold_date_sk
LEFT JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws_site           ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN inventory inv              ON inv.inv_warehouse_sk = w.w_warehouse_sk
                                    AND inv.inv_date_sk = cs_agg.cs_sold_date_sk
LEFT JOIN store s                    ON s.s_closed_date_sk = cs_agg.cs_sold_date_sk
-- Re‑use call_center under a different alias for a different role
LEFT JOIN call_center cc2            ON cc2.cc_open_date_sk = cs_agg.cs_sold_date_sk
WHERE cs_agg.cs_call_center_sk IN (
        SELECT cc_call_center_sk FROM call_center WHERE cc_country = 'United States'
      )
  AND c.c_customer_sk IN (SELECT customer_sk FROM customer_intersect)
GROUP BY
  d_sold.d_year,
  c.c_customer_id,
  cc.cc_name,
  w.w_warehouse_name,
  p.p_promo_name
ORDER BY
  sum_total_net_paid DESC
LIMIT 100
