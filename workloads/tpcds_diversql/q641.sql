WITH
  -- Sample a fraction of catalog_sales
  sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Pre‑aggregate store_sales per item, store and ticket
  agg_ss AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      ss_ticket_number,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk, ss_ticket_number
  ),
  -- Intersection of order numbers appearing in catalog_returns and store_returns
  intersect_orders AS (
    SELECT cr_order_number AS order_key FROM catalog_returns
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
  ),
  -- Scalar subquery returning a single value (average tax of all catalog sales)
  scalar_avg_tax AS (
    SELECT AVG(cs_ext_tax) AS avg_tax FROM catalog_sales
  )
SELECT
  cr.cr_order_number,
  cr.cr_return_amount,
  cr.cr_net_loss,
  cs.cs_ext_tax,
  ss_agg.total_profit,
  r.r_reason_desc,
  ib.ib_lower_bound,
  ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC) AS rn
FROM catalog_returns cr
-- join to sampled catalog_sales (order number rule)
JOIN sampled_cs cs
  ON cr.cr_order_number = cs.cs_order_number
-- join to the aggregated store_sales via item and ticket (store_returns will link later)
JOIN agg_ss ss_agg
  ON ss_agg.ss_item_sk = cs.cs_item_sk
-- join to store_returns that matches the same item and ticket (store_returns rule)
JOIN store_returns sr
  ON sr.sr_item_sk = ss_agg.ss_item_sk
 AND sr.sr_ticket_number = ss_agg.ss_ticket_number
-- join to store (store_sales rule via store_returns)
JOIN store s
  ON s.s_store_sk = sr.sr_store_sk
-- join to reason through store_returns (reason rule)
JOIN reason r
  ON r.r_reason_sk = sr.sr_reason_sk
-- join to household_demographics for the refunded household (catalog_returns rule)
JOIN household_demographics hd_ref
  ON hd_ref.hd_demo_sk = cr.cr_refunded_hdemo_sk
-- join to income_band (demographics rule)
JOIN income_band ib
  ON ib.ib_income_band_sk = hd_ref.hd_income_band_sk
-- join to customer_address for the refunded address (catalog_returns rule)
JOIN customer_address ca_ref
  ON ca_ref.ca_address_sk = cr.cr_refunded_addr_sk
-- join to household_demographics for the store return household (store_returns rule, second alias)
JOIN household_demographics hd_ret
  ON hd_ret.hd_demo_sk = sr.sr_hdemo_sk
-- join to customer_address for the store return address (store_returns rule, second alias)
JOIN customer_address ca_ret
  ON ca_ret.ca_address_sk = sr.sr_addr_sk
-- join time dimensions for various events (time_dim rules, three aliases)
JOIN time_dim t_cr
  ON t_cr.t_time_sk = cr.cr_returned_time_sk
JOIN time_dim t_cs
  ON t_cs.t_time_sk = cs.cs_sold_time_sk
JOIN time_dim t_sr
  ON t_sr.t_time_sk = sr.sr_return_time_sk
-- ensure the order number is present in the intersect set
JOIN intersect_orders io
  ON io.order_key = cr.cr_order_number
WHERE
  -- compare a column against the scalar subquery value
  cs.cs_ext_tax > (SELECT avg_tax FROM scalar_avg_tax)
  -- anti‑join: keep rows where no web return exists for the same order number
  AND NOT EXISTS (
    SELECT 1 FROM web_returns wr
    WHERE wr.wr_order_number = cr.cr_order_number
  )
ORDER BY rn DESC
LIMIT 100
