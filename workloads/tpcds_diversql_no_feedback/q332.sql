WITH sales_returns_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    p.p_promo_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_txn_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(ss.ss_ext_wholesale_cost) AS total_wholesale_cost,
    SUM(ss.ss_ext_list_price) AS total_list_price,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
  WHERE ss.ss_ext_wholesale_cost > 4000
    AND ss.ss_ext_list_price < 12000
    AND hd.hd_dep_count >= 2
    AND s.s_rec_start_date >= DATE '2000-01-01'
    AND ib.ib_upper_bound < 50000
    AND (sr.sr_reversed_charge IS NULL OR sr.sr_reversed_charge > 10)
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    p.p_promo_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
)
SELECT
  s_store_sk,
  s_store_name,
  p_promo_id,
  total_net_profit,
  sales_txn_count,
  total_return_amount,
  total_wholesale_cost,
  total_list_price,
  ib_lower_bound,
  ib_upper_bound,
  hd_buy_potential,
  RANK() OVER (PARTITION BY s_store_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_returns_agg
ORDER BY total_net_profit DESC
LIMIT 100
