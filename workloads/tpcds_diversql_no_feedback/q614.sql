WITH
  -- Base query joining all 14 tables in a left‑deep chain, using two aliases for DATE_DIM
  base_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      s.s_store_name,
      p.p_promo_name,
      d1.d_year,
      cr.cr_return_amount,
      cr.cr_return_tax,
      ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS return_vals,
      -- bring a few extra columns to satisfy join rules (not necessarily used later)
      c.c_customer_id,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name,
      wp.wp_url,
      wr.wr_return_amt,
      ws.web_name
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
    JOIN date_dim d2 ON ws.web_close_date_sk = d2.d_date_sk
    WHERE d1.d_year = 2001
  ),

  -- Unnest the array built from catalog return amounts
  unnested_returns AS (
    SELECT
      bd.*, rv AS single_return_value
    FROM base_data bd
    CROSS JOIN UNNEST(bd.return_vals) AS t(rv)
  ),

  -- Stores that had sales on a specific surrogate date but never appeared in returns (EXCEPT)
  stores_without_returns AS (
    SELECT s1.s_store_id
    FROM store_sales ss1
    JOIN store s1 ON ss1.ss_store_sk = s1.s_store_sk
    WHERE ss1.ss_sold_date_sk = 123456  -- example surrogate key for a given day
    EXCEPT
    SELECT s2.s_store_id
    FROM store_returns sr1
    JOIN store s2 ON sr1.sr_store_sk = s2.s_store_sk
    WHERE sr1.sr_returned_date_sk = 123456
  )

SELECT
  COALESCE(u.s_store_name, 'ALL')               AS store_name,
  COALESCE(u.p_promo_name, 'ALL')               AS promo_name,
  CASE WHEN SUM(u.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
  SUM(u.ss_ext_sales_price)                    AS total_sales,
  SUM(u.single_return_value)                   AS total_return_amount,
  (SELECT COUNT(*) FROM stores_without_returns) AS stores_sold_no_return
FROM unnested_returns u
GROUP BY GROUPING SETS (
  (u.s_store_name, u.p_promo_name),
  (u.s_store_name),
  (u.p_promo_name),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
