WITH sales_agg AS (
  SELECT i.i_category,
         d.d_year,
         SUM(ss.ss_net_profit) AS store_net_profit,
         SUM(ss.ss_ext_discount_amt) AS store_discount,
         COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, d.d_year
),
web_sales_agg AS (
  SELECT i.i_category,
         d.d_year,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_ext_discount_amt) AS web_discount,
         COUNT(DISTINCT ws.ws_order_number) AS web_txn_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, d.d_year
),
returns_agg AS (
  SELECT i.i_category,
         d.d_year,
         SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
         SUM(COALESCE(cr.cr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty
  FROM (
        SELECT cr_returned_date_sk, cr_item_sk, cr_net_loss, cr_return_quantity
        FROM catalog_returns
      ) cr
  FULL OUTER JOIN (
        SELECT wr_returned_date_sk, wr_item_sk, wr_net_loss, wr_return_quantity
        FROM web_returns
      ) wr
    ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
   AND cr.cr_item_sk = wr.wr_item_sk
  JOIN date_dim d ON COALESCE(cr.cr_returned_date_sk, wr.wr_returned_date_sk) = d.d_date_sk
  JOIN item i ON COALESCE(cr.cr_item_sk, wr.wr_item_sk) = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, d.d_year
)
SELECT
  s.i_category,
  s.d_year,
  (s.store_net_profit + w.web_net_profit - COALESCE(r.total_return_loss, 0)) AS adjusted_net_profit,
  (s.store_discount + w.web_discount) AS total_discount,
  COALESCE(r.total_return_qty, 0) AS return_quantity,
  ROW_NUMBER() OVER (ORDER BY (s.store_net_profit + w.web_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS rank
FROM sales_agg s
JOIN web_sales_agg w ON s.i_category = w.i_category AND s.d_year = w.d_year
LEFT JOIN returns_agg r ON s.i_category = r.i_category AND s.d_year = r.d_year
WHERE (s.store_net_profit + w.web_net_profit - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY adjusted_net_profit DESC
LIMIT 5
