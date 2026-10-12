WITH unified AS (
  -- Store Sales branch (includes store, returns, and dimensions)
  SELECT
    s.s_store_name AS store_name,
    ca.ca_state AS state,
    ss.ss_net_profit AS profit,
    0.0 AS extra_loss
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd_cust ON ss.ss_hdemo_sk = hd_cust.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN income_band ib ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  LEFT JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk

  UNION DISTINCT

  -- Catalog Sales branch (includes ship mode, web returns and dimensions)
  SELECT
    CAST(NULL AS varchar) AS store_name,
    ca2.ca_state AS state,
    cs.cs_net_profit AS profit,
    0.0 AS extra_loss
  FROM catalog_sales cs
  JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
  JOIN customer c2 ON cs.cs_bill_customer_sk = c2.c_customer_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca2 ON cs.cs_bill_addr_sk = ca2.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
  JOIN income_band ib2 ON hd_bill.hd_income_band_sk = ib2.ib_income_band_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i2.i_item_sk
                              AND wr.wr_refunded_customer_sk = c2.c_customer_sk
  LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
  LEFT JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
),
agg AS (
  SELECT
    store_name,
    state,
    SUM(profit + extra_loss) AS total_profit
  FROM unified
  GROUP BY store_name, state
  HAVING SUM(profit + extra_loss) > (SELECT AVG(cs_net_profit) FROM catalog_sales)
)
SELECT
  store_name,
  state,
  total_profit,
  LAG(total_profit) OVER (ORDER BY total_profit DESC) AS prev_total_profit
FROM agg
ORDER BY total_profit DESC
LIMIT 100
