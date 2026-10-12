SELECT
  ib.ib_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  c.c_birth_month,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_paid) AS total_net_paid,
  AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
  SUM(ws.ws_ext_discount_amt) AS total_discount,
  RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS profit_rank
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
  AND c.c_birth_year BETWEEN 1960 AND 1990
  AND ws.ws_coupon_amt > 0
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, c.c_birth_month
HAVING COUNT(*) > 20
ORDER BY total_net_paid DESC
LIMIT 20
