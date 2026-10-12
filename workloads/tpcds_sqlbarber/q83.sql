SELECT
    cc.cc_call_center_id,
    d.d_year,
    cs.cs_order_number,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    (SELECT MAX(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_returned_date_sk = 2451056) AS sample_return_amount
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
WHERE d.d_year = 1910
GROUP BY cc.cc_call_center_id, d.d_year, cs.cs_order_number
HAVING SUM(cs.cs_net_profit) > -73.64
