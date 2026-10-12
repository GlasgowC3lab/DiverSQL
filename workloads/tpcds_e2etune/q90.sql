WITH
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ss.ss_item_sk,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ss.ss_item_sk
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cr.cr_item_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss,
      SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cr.cr_item_sk
  ),
  inventory_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
      d.d_year,
      d.d_month_seq,
      inv.inv_item_sk
  )
SELECT
  s.d_year,
  s.d_month_seq,
  s.hd_income_band_sk,
  s.ib_lower_bound,
  s.ib_upper_bound,
  s.ss_item_sk AS item_sk,
  s.total_sales,
  COALESCE(r.total_return_amount, 0) AS total_returns,
  (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
  s.total_profit,
  COALESCE(i.total_on_hand, 0) AS inventory_on_hand,
  RANK() OVER (PARTITION BY s.d_year ORDER BY (s.total_sales - COALESCE(r.total_return_amount, 0)) DESC) AS sales_rank_month
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.hd_income_band_sk = r.hd_income_band_sk
 AND s.ss_item_sk = r.cr_item_sk
LEFT JOIN inventory_agg i
  ON s.d_year = i.d_year
 AND s.d_month_seq = i.d_month_seq
 AND s.ss_item_sk = i.inv_item_sk
WHERE s.total_sales > 10000
ORDER BY s.d_year, s.d_month_seq, net_sales DESC
LIMIT 100
