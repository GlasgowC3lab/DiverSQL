WITH joined AS (
  SELECT
    date_dim.d_year,
    item.i_brand,
    reason.r_reason_desc,
    warehouse.w_country,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    store_returns.sr_return_amt,
    store_returns.sr_return_tax,
    store_returns.sr_net_loss,
    catalog_returns.cr_return_amount,
    catalog_returns.cr_return_tax,
    catalog_returns.cr_net_loss,
    catalog_returns.cr_order_number,
    web_returns.wr_return_amt,
    web_returns.wr_return_tax,
    web_returns.wr_net_loss
  FROM store_returns
  JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
  JOIN time_dim ON store_returns.sr_return_time_sk = time_dim.t_time_sk
  JOIN item ON store_returns.sr_item_sk = item.i_item_sk
  JOIN customer_demographics ON store_returns.sr_cdemo_sk = customer_demographics.cd_demo_sk
  JOIN household_demographics ON store_returns.sr_hdemo_sk = household_demographics.hd_demo_sk
  JOIN customer_address ON store_returns.sr_addr_sk = customer_address.ca_address_sk
  JOIN store ON store_returns.sr_store_sk = store.s_store_sk
  JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
  JOIN catalog_returns ON catalog_returns.cr_item_sk = item.i_item_sk
    AND catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    AND catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
    AND catalog_returns.cr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
    AND catalog_returns.cr_refunded_hdemo_sk = household_demographics.hd_demo_sk
    AND catalog_returns.cr_refunded_addr_sk = customer_address.ca_address_sk
  JOIN ship_mode ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
  JOIN warehouse ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
  JOIN web_returns ON web_returns.wr_item_sk = item.i_item_sk
    AND web_returns.wr_returned_date_sk = date_dim.d_date_sk
    AND web_returns.wr_returned_time_sk = time_dim.t_time_sk
    AND web_returns.wr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
    AND web_returns.wr_refunded_hdemo_sk = household_demographics.hd_demo_sk
    AND web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
  JOIN web_page ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
  JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
  WHERE date_dim.d_year = 2001
    AND item.i_brand = 'Brand#23'
    AND reason.r_reason_desc LIKE '%Did not fit%'
    AND warehouse.w_country = 'United States'
    AND income_band.ib_lower_bound >= 50000
)
SELECT
  d_year,
  i_brand,
  r_reason_desc,
  w_country,
  ib_lower_bound,
  ib_upper_bound,
  SUM(sr_return_amt) AS sum_store_return_amt,
  SUM(cr_return_amount) AS sum_catalog_return_amt,
  SUM(wr_return_amt) AS sum_web_return_amt,
  AVG(sr_net_loss) AS avg_store_net_loss,
  COUNT(DISTINCT cr_order_number) AS distinct_catalog_orders,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (SUM(sr_return_amt) + SUM(cr_return_amount) + SUM(wr_return_amt)) DESC) AS return_rank
FROM joined
GROUP BY
  d_year,
  i_brand,
  r_reason_desc,
  w_country,
  ib_lower_bound,
  ib_upper_bound
ORDER BY return_rank
LIMIT 100
