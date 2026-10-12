WITH returns_sales AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_reason_sk,
    cr.cr_returned_date_sk,
    i.i_category,
    i.i_brand,
    r.r_reason_desc
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_return_quantity > 10
    AND cs.cs_net_profit > 0
)
SELECT
  i_category,
  i_brand,
  r_reason_desc,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cr_return_tax) AS total_return_tax,
  COUNT(*) AS return_cnt,
  AVG(cs_net_paid) AS avg_sales_net_paid,
  RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS return_amount_rank
FROM returns_sales
GROUP BY i_category, i_brand, r_reason_desc
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 20
