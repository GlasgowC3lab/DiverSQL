SELECT
  c.c_birth_country,
  s.cs_ship_mode_sk,
  SUM(s.total_net_paid) AS total_net_paid,
  SUM(s.total_quantity) AS total_quantity,
  SUM(s.total_profit) AS total_profit,
  AVG(s.avg_sales_price) AS avg_sales_price,
  COALESCE(SUM(r.total_store_return_amt), 0) AS total_store_return_amt,
  COALESCE(SUM(r.total_store_net_loss), 0) AS total_store_net_loss,
  COALESCE(SUM(w.total_web_return_amt), 0) AS total_web_return_amt,
  COALESCE(SUM(w.total_web_net_loss), 0) AS total_web_net_loss,
  COALESCE(SUM(r.total_store_net_loss), 0) + COALESCE(SUM(w.total_web_net_loss), 0) AS total_return_loss
FROM (
  SELECT
    cs_bill_customer_sk AS cust_sk,
    cs_ship_mode_sk,
    SUM(cs_net_paid_inc_ship) AS total_net_paid,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_sales_price) AS avg_sales_price
  FROM catalog_sales
  WHERE cs_net_paid_inc_ship > 3000
    AND cs_quantity BETWEEN 50 AND 80
    AND cs_ship_mode_sk IN (1, 5, 18)
  GROUP BY cs_bill_customer_sk, cs_ship_mode_sk
) s
JOIN customer c
  ON s.cust_sk = c.c_customer_sk
LEFT JOIN (
  SELECT
    sr_customer_sk AS cust_sk,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(sr_net_loss) AS total_store_net_loss
  FROM store_returns
  WHERE sr_return_amt > 1000
  GROUP BY sr_customer_sk
) r
  ON c.c_customer_sk = r.cust_sk
LEFT JOIN (
  SELECT
    wr_refunded_customer_sk AS cust_sk,
    SUM(wr_return_amt) AS total_web_return_amt,
    SUM(wr_net_loss) AS total_web_net_loss
  FROM web_returns
  WHERE wr_return_amt > 500
  GROUP BY wr_refunded_customer_sk
) w
  ON c.c_customer_sk = w.cust_sk
WHERE c.c_birth_country IN ('United States', 'Canada')
GROUP BY c.c_birth_country, s.cs_ship_mode_sk
ORDER BY total_net_paid DESC
LIMIT 100
