WITH
  -- Base sales data joining all tables except web_returns
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_net_paid,
      s.s_store_name,
      s.s_number_employees,
      p.p_promo_name,
      p.p_discount_active,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      cr.cr_return_amount,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name,
      w.w_gmt_offset
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr
      ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    LEFT JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
      ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE s.s_number_employees > 250
      AND p.p_discount_active = 'Y'
      AND w.w_gmt_offset > -5.0
  ),

  -- Web‑return side (also uses household_demographics)
  web_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_amt,
      wr.wr_account_credit,
      hd.hd_income_band_sk,
      hd.hd_buy_potential
    FROM web_returns wr
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_account_credit > 0
  ),

  -- Full outer join of the two sides (keeps unmatched rows from both)
  combined AS (
    SELECT
      sb.ss_sold_date_sk,
      sb.ss_item_sk               AS sb_item_sk,
      sb.ss_store_sk,
      sb.s_store_name,
      sb.s_number_employees,
      sb.p_promo_name,
      sb.p_discount_active,
      sb.hd_income_band_sk,
      sb.hd_buy_potential,
      sb.ss_net_paid,
      sb.cr_return_amount,
      sb.inv_quantity_on_hand,
      sb.w_warehouse_name,
      wb.wr_returned_date_sk,
      wb.wr_item_sk               AS wb_item_sk,
      wb.wr_return_amt,
      wb.wr_account_credit
    FROM sales_base sb
    FULL OUTER JOIN web_base wb
      ON sb.ss_item_sk = wb.wr_item_sk
      AND sb.hd_income_band_sk = wb.hd_income_band_sk
  ),

  -- Aggregation with GROUPING SETS
  agg AS (
    SELECT
      COALESCE(s_store_name, 'UNKNOWN')                      AS store_name,
      COALESCE(p_promo_name, 'NONE')                         AS promo_name,
      hd_income_band_sk,
      SUM(CASE WHEN ss_net_paid IS NOT NULL THEN ss_net_paid ELSE 0 END)       AS total_sales,
      SUM(CASE WHEN cr_return_amount IS NOT NULL THEN cr_return_amount ELSE 0 END) AS total_catalog_returns,
      SUM(CASE WHEN wr_return_amt IS NOT NULL THEN wr_return_amt ELSE 0 END)   AS total_web_returns,
      COUNT(*)                                               AS transaction_cnt
    FROM combined
    GROUP BY GROUPING SETS (
      (s_store_name, p_promo_name, hd_income_band_sk),
      (s_store_name, hd_income_band_sk),
      (p_promo_name, hd_income_band_sk),
      (hd_income_band_sk)
    )
  ),

  -- Ranking and categorisation
  ranked AS (
    SELECT
      store_name,
      promo_name,
      hd_income_band_sk,
      total_sales,
      total_catalog_returns,
      total_web_returns,
      transaction_cnt,
      ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank,
      CASE
        WHEN total_sales > 100000 THEN 'HIGH'
        WHEN total_sales > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
      END AS sales_category
    FROM agg
  )

-- Final result: keep HIGH & MEDIUM rows but remove any that also appear as LOW (EXCEPT), order and limit
SELECT
  store_name,
  promo_name,
  hd_income_band_sk,
  total_sales,
  total_catalog_returns,
  total_web_returns,
  transaction_cnt,
  sales_rank,
  sales_category
FROM (
  SELECT * FROM ranked WHERE sales_category IN ('HIGH', 'MEDIUM')
  EXCEPT
  SELECT * FROM ranked WHERE sales_category = 'LOW'
) AS final_set
ORDER BY total_sales DESC
LIMIT 100
