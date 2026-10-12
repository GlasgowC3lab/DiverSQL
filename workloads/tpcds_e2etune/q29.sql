SELECT
    s.s_store_id,
    s.s_state,
    d.cd_gender,
    hd.hd_income_band_sk,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
    SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunds,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_net_paid_inc_tax) - SUM(COALESCE(sr.sr_refunded_cash, 0))) AS net_revenue,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (SUM(ss.ss_net_paid_inc_tax) - SUM(COALESCE(sr.sr_refunded_cash, 0))) DESC) AS revenue_rank_state
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics d
  ON ss.ss_cdemo_sk = d.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
WHERE s.s_state = 'AZ'
  AND d.cd_gender = 'M'
  AND ca.ca_country = 'United States'
  AND hd.hd_income_band_sk BETWEEN 1 AND 3
GROUP BY s.s_store_id, s.s_state, d.cd_gender, hd.hd_income_band_sk
HAVING SUM(ss.ss_net_paid_inc_tax) > 10000
ORDER BY net_revenue DESC
LIMIT 100
