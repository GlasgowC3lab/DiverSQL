SELECT cd.cd_gender,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM customer_demographics cd
JOIN catalog_returns cr
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN (
    SELECT sr.sr_cdemo_sk, sr.sr_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 26.60
) sr_sub
  ON sr_sub.sr_cdemo_sk = cd.cd_demo_sk
GROUP BY cd.cd_gender
HAVING SUM(cr.cr_return_amount) > 29.79
