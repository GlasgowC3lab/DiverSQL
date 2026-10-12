WITH filtered AS (
  SELECT
    cc.cc_name,
    cc.cc_country,
    cc.cc_street_name,
    dd.d_year,
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_promo_sk,
    ss.ss_quantity,
    ss.ss_ext_discount_amt,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_store_sk,
    ss.ss_ticket_number,
    pr.p_promo_name,
    pr.p_discount_active,
    cu.c_customer_sk
  FROM call_center cc
  INNER JOIN date_dim dd
    ON cc.cc_closed_date_sk = dd.d_date_sk
  RIGHT JOIN store_sales ss
    ON ss.ss_sold_date_sk = dd.d_date_sk
  INNER JOIN customer cu
    ON ss.ss_customer_sk = cu.c_customer_sk
  INNER JOIN promotion pr
    ON ss.ss_promo_sk = pr.p_promo_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd.d_date_sk
      AND wr.wr_returning_customer_sk = cu.c_customer_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = dd.d_date_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = dd.d_date_sk
      AND inv.inv_item_sk = ss.ss_item_sk
  WHERE
    cc.cc_country = 'United States'
    AND cc.cc_street_name IN ('Ash Hill', 'Main')
    AND dd.d_year = 2001
    AND pr.p_discount_active = 'Y'
    AND ss.ss_quantity > 5
    AND ss.ss_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 600)
),
agg AS (
  SELECT
    f.d_year,
    f.cc_name,
    f.p_promo_name,
    CASE WHEN f.ss_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_level,
    f.ss_store_sk,
    SUM(f.ss_net_paid) AS total_sales,
    AVG(f.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT f.ss_ticket_number) AS order_count,
    MIN(f.ss_net_profit) AS min_profit,
    MAX(f.ss_net_profit) AS max_profit,
    f.c_customer_sk
  FROM filtered f
  GROUP BY
    f.d_year,
    f.cc_name,
    f.p_promo_name,
    CASE WHEN f.ss_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END,
    f.ss_store_sk,
    f.c_customer_sk
)
SELECT
  a.d_year,
  a.cc_name,
  a.p_promo_name,
  a.discount_level,
  a.total_sales,
  a.avg_discount,
  a.order_count,
  a.min_profit,
  a.max_profit,
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = a.c_customer_sk
  ) AS total_return_amt,
  RANK() OVER (PARTITION BY a.ss_store_sk ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
