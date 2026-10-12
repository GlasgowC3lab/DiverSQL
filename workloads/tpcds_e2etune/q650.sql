WITH cat_ret AS (
  SELECT
    p.p_promo_name,
    r.r_reason_desc,
    w.w_warehouse_name AS location,
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_refunded_customer_sk
  FROM catalog_returns cr
  JOIN promotion p ON cr.cr_item_sk = p.p_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_ship_mode_sk IN (2, 13)
    AND cr.cr_returned_date_sk BETWEEN 2458840 AND 2459200
),
web_ret AS (
  SELECT
    p.p_promo_name,
    r.r_reason_desc,
    wp.wp_type AS location,
    wr.wr_returned_date_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    wr.wr_refunded_customer_sk
  FROM web_returns wr
  JOIN promotion p ON wr.wr_item_sk = p.p_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_return_quantity > 0
    AND wr.wr_returned_date_sk BETWEEN 2458840 AND 2459200
)
SELECT
  promo_name,
  reason_desc,
  location,
  SUM(return_quantity) AS total_return_qty,
  SUM(return_amount) AS total_return_amount,
  SUM(net_loss) AS total_net_loss,
  COUNT(DISTINCT refunded_customer_sk) AS distinct_customers,
  AVG(return_amount) AS avg_return_amount,
  RANK() OVER (PARTITION BY location ORDER BY SUM(net_loss) DESC) AS net_loss_rank
FROM (
  SELECT
    p_promo_name AS promo_name,
    r_reason_desc AS reason_desc,
    location,
    cr_return_quantity AS return_quantity,
    cr_return_amount AS return_amount,
    cr_net_loss AS net_loss,
    cr_refunded_customer_sk AS refunded_customer_sk
  FROM cat_ret
  UNION ALL
  SELECT
    p_promo_name AS promo_name,
    r_reason_desc AS reason_desc,
    location,
    wr_return_quantity AS return_quantity,
    wr_return_amt AS return_amount,
    wr_net_loss AS net_loss,
    wr_refunded_customer_sk AS refunded_customer_sk
  FROM web_ret
) AS unified
GROUP BY promo_name, reason_desc, location
ORDER BY total_net_loss DESC
LIMIT 100
