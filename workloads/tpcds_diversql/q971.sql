WITH
  sales_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_net_profit,
      ss.ss_quantity,
      i.i_manufact_id,
      i.i_wholesale_cost,
      d.d_year,
      d.d_weekend,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca     ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  returns_data AS (
    SELECT
      cr.cr_returned_date_sk   AS returned_date_sk,
      cr.cr_item_sk            AS item_sk,
      cr.cr_return_quantity    AS return_quantity,
      cr.cr_return_amount      AS return_amount,
      cr.cr_net_loss           AS net_loss,
      i.i_manufact_id,
      d.d_year,
      d.d_weekend,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      'catalog'                AS source
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    SELECT
      wr.wr_returned_date_sk   AS returned_date_sk,
      wr.wr_item_sk            AS item_sk,
      wr.wr_return_quantity    AS return_quantity,
      wr.wr_return_amt         AS return_amount,
      wr.wr_net_loss           AS net_loss,
      i.i_manufact_id,
      d.d_year,
      d.d_weekend,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      'web'                    AS source
    FROM web_returns wr
    JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca     ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  items_without_returns AS (
    SELECT DISTINCT sd.ss_item_sk AS item_sk
    FROM sales_data sd
    EXCEPT
    SELECT DISTINCT rd.item_sk
    FROM returns_data rd
  )
SELECT
  s.s_store_name,
  s.s_state,
  COALESCE(SUM(sd.ss_net_profit), 0)                              AS total_net_profit,
  COUNT(DISTINCT sd.ss_item_sk)                                 AS distinct_items_sold,
  COUNT(DISTINCT iwr.item_sk)                                   AS items_without_returns,
  CASE
    WHEN COALESCE(SUM(sd.ss_net_profit), 0) > 100000 THEN 'HIGH'
    WHEN COALESCE(SUM(sd.ss_net_profit), 0) < 0       THEN 'LOSS'
    ELSE 'MEDIUM'
  END                                                          AS profit_category,
  MAX(ws.web_name)                                              AS web_site_name,
  ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(sd.ss_net_profit), 0) DESC) AS store_rank
FROM store s
RIGHT JOIN sales_data sd ON s.s_store_sk = sd.ss_store_sk
LEFT  JOIN returns_data rd ON rd.item_sk = sd.ss_item_sk AND rd.returned_date_sk = sd.ss_sold_date_sk
LEFT  JOIN web_site ws     ON ws.web_open_date_sk = sd.ss_sold_date_sk
LEFT  JOIN items_without_returns iwr ON iwr.item_sk = sd.ss_item_sk
WHERE
  sd.d_year BETWEEN 2000 AND 2002
  AND sd.i_wholesale_cost > 1.00
  AND sd.hd_income_band_sk IN (4, 9, 17)
  AND sd.d_weekend = 'N'
GROUP BY
  s.s_store_name,
  s.s_state,
  ws.web_name
ORDER BY
  total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
