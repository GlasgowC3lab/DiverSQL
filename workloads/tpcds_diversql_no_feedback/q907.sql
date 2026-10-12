WITH joined AS (
  SELECT
    s.s_state,
    p.p_promo_id,
    d.d_year,
    ss.ss_net_paid,
    ss.ss_net_profit,
    sr.sr_return_amt,
    ss.ss_customer_sk,
    ca.ca_gmt_offset,
    ws.web_site_id
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
)
SELECT
  COALESCE(s_state, 'ALL') AS store_state,
  COALESCE(p_promo_id, 'ALL') AS promo_id,
  d_year,
  SUM(ss_net_paid) AS total_net_paid,
  SUM(sr_return_amt) AS total_return_amt,
  COUNT(DISTINCT ss_customer_sk) AS unique_customers,
  CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(s_state, 'ALL') ORDER BY SUM(ss_net_paid) DESC) AS state_rank
FROM joined
GROUP BY GROUPING SETS (
  (s_state, p_promo_id, d_year),
  (s_state, d_year),
  (p_promo_id, d_year),
  (d_year)
)
HAVING SUM(ss_net_paid) > 1000
ORDER BY state_rank, total_net_paid DESC
LIMIT 100
