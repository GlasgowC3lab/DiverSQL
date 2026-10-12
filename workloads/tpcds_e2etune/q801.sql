WITH demo_sales AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_buy_potential,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
    SUM(cs.cs_ext_tax) AS total_ext_tax
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_wholesale_cost > 50.00
    AND cs.cs_ext_tax BETWEEN 0 AND 100
  GROUP BY
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_buy_potential
),

demo_returns AS (
  SELECT
    hd.hd_demo_sk,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(sr.sr_ticket_number) AS return_tickets,
    SUM(sr.sr_return_quantity) AS total_return_quantity
  FROM store_returns sr
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  GROUP BY
    hd.hd_demo_sk
)
SELECT
  ds.hd_demo_sk,
  ds.hd_vehicle_count,
  ds.hd_income_band_sk,
  ds.hd_dep_count,
  ds.hd_buy_potential,
  ds.total_net_profit,
  ds.total_net_paid,
  ds.sales_orders,
  ds.avg_wholesale_cost,
  dr.total_return_amount,
  dr.total_return_loss,
  dr.return_tickets,
  CASE WHEN ds.total_net_profit <> 0 THEN dr.total_return_loss / ds.total_net_profit ELSE NULL END AS return_loss_ratio,
  RANK() OVER (ORDER BY ds.total_net_profit DESC) AS profit_rank
FROM demo_sales ds
LEFT JOIN demo_returns dr
  ON ds.hd_demo_sk = dr.hd_demo_sk
WHERE ds.total_net_profit > 5000
ORDER BY return_loss_ratio DESC NULLS LAST, ds.total_net_profit DESC
LIMIT 10
