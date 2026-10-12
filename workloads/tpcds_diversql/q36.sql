WITH cs AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_sold_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_promo_sk,
    cs.cs_net_paid,
    cs.cs_ext_sales_price
  FROM catalog_sales cs
  WHERE cs.cs_net_paid > 1000
    AND cs.cs_ext_sales_price BETWEEN 500 AND 5000
    AND cs.cs_item_sk IN (131524, 193426, 98858)
),
ss AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_customer_sk,
    ss.ss_hdemo_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_ext_sales_price
  FROM store_sales ss
  WHERE ss.ss_net_paid > 500
    AND ss.ss_quantity >= 2
    AND ss.ss_ticket_number IS NOT NULL
),
sr AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_returned_date_sk,
    sr.sr_return_amt,
    sr.sr_refunded_cash
  FROM store_returns sr
  WHERE sr.sr_return_amt > 0
    AND sr.sr_refunded_cash > 0
)
SELECT
  d.d_year,
  d.d_month_seq,
  c.c_customer_id,
  hd.hd_buy_potential,
  p.p_promo_name,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  SUM(cs.cs_net_paid) AS catalog_net_paid,
  SUM(ss.ss_net_paid) AS store_net_paid,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
  AVG(cs.cs_ext_sales_price) AS avg_catalog_ext_price,
  MAX(ss.ss_ext_sales_price) AS max_store_ext_price,
  (
    SELECT MAX(p2.p_cost)
    FROM promotion p2
    WHERE p2.p_channel_tv = 'Y'
  ) AS max_tv_promo_cost
FROM store_sales ss
FULL OUTER JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
  AND cs.cs_bill_customer_sk = c.c_customer_sk
  AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  AND cs.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND d.d_month_seq = 7
  AND c.c_preferred_cust_flag = 'Y'
  AND hd.hd_vehicle_count >= 1
  AND p.p_channel_radio = 'N'
  AND p.p_discount_active = 'Y'
GROUP BY
  d.d_year,
  d.d_month_seq,
  c.c_customer_id,
  hd.hd_buy_potential,
  p.p_promo_name
HAVING
  SUM(cs.cs_net_paid) > 5000
ORDER BY
  catalog_net_paid DESC
LIMIT 100
