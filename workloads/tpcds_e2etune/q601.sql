WITH catalog_agg AS (
  SELECT
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND cs.cs_promo_sk IN (1023, 1057, 1374)
  GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
),
store_agg AS (
  SELECT
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
),
returns_agg AS (
  SELECT
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(wr.wr_net_loss) AS returns_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
),
returns_page_agg AS (
  SELECT
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_return_pages
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
  ca.d_year,
  ca.ib_lower_bound,
  ca.ib_upper_bound,
  ca.catalog_net_profit,
  sa.store_net_profit,
  ra.returns_net_loss,
  ca.avg_catalog_discount,
  sa.distinct_store_customers,
  rp.distinct_return_pages,
  (ca.catalog_net_profit + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.returns_net_loss, 0)) AS total_net_profit,
  RANK() OVER (PARTITION BY ca.d_year ORDER BY (ca.catalog_net_profit + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.returns_net_loss, 0)) DESC) AS profit_rank
FROM catalog_agg ca
LEFT JOIN store_agg sa
  ON ca.d_year = sa.d_year
  AND ca.ib_lower_bound = sa.ib_lower_bound
  AND ca.ib_upper_bound = sa.ib_upper_bound
LEFT JOIN returns_agg ra
  ON ca.d_year = ra.d_year
  AND ca.ib_lower_bound = ra.ib_lower_bound
  AND ca.ib_upper_bound = ra.ib_upper_bound
LEFT JOIN returns_page_agg rp
  ON ca.d_year = rp.d_year
  AND ca.ib_lower_bound = rp.ib_lower_bound
  AND ca.ib_upper_bound = rp.ib_upper_bound
WHERE (ca.catalog_net_profit + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.returns_net_loss, 0)) > 0
ORDER BY ca.d_year, profit_rank
LIMIT 100
