WITH all_returns AS (
  SELECT i.i_category AS category,
         cr.cr_net_loss AS net_loss,
         cr.cr_return_quantity AS return_qty
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
  WHERE c.c_birth_month = 5
    AND c.c_birth_year = 1985
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450500
    AND cr.cr_refunded_addr_sk IN (2409583, 3405652)
  UNION ALL
  SELECT i.i_category AS category,
         sr.sr_net_loss AS net_loss,
         sr.sr_return_quantity AS return_qty
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  WHERE c.c_birth_month = 5
    AND c.c_birth_year = 1985
    AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450500
    AND sr.sr_return_quantity > 0
  UNION ALL
  SELECT i.i_category AS category,
         wr.wr_net_loss AS net_loss,
         wr.wr_return_quantity AS return_qty
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE c.c_birth_month = 5
    AND c.c_birth_year = 1985
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450500
    AND wp.wp_type = 'product'
)
SELECT
  category,
  total_net_loss,
  total_return_qty,
  avg_loss_per_return,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM (
  SELECT
    category,
    SUM(net_loss) AS total_net_loss,
    SUM(return_qty) AS total_return_qty,
    CASE WHEN SUM(return_qty) > 0 THEN SUM(net_loss) / SUM(return_qty) ELSE NULL END AS avg_loss_per_return
  FROM all_returns
  GROUP BY category
  HAVING SUM(return_qty) >= 10
) agg
ORDER BY total_net_loss DESC
LIMIT 10
