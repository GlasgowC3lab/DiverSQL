WITH
store_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(ss.ss_net_profit) AS store_profit,
         SUM(ss.ss_quantity) AS store_qty,
         COUNT(DISTINCT ss.ss_customer_sk) AS store_cust_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
store_returns_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(sr.sr_net_loss) AS store_return_loss,
         SUM(sr.sr_return_quantity) AS store_ret_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
web_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(ws.ws_net_profit) AS web_profit,
         SUM(ws.ws_quantity) AS web_qty,
         COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_cust_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
web_returns_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(wr.wr_net_loss) AS web_return_loss,
         SUM(wr.wr_return_quantity) AS web_ret_qty
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
catalog_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(cs.cs_net_profit) AS catalog_profit,
         SUM(cs.cs_quantity) AS catalog_qty,
         COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_cust_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
catalog_returns_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         d.d_year,
         SUM(cr.cr_net_loss) AS catalog_return_loss,
         SUM(cr.cr_return_quantity) AS catalog_ret_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY i.i_category_id, i.i_category, d.d_year
),
combined AS (
  SELECT
    COALESCE(sa.i_category_id, ra.i_category_id, wa.i_category_id, wra.i_category_id, ca.i_category_id, cra.i_category_id) AS category_id,
    COALESCE(sa.i_category, ra.i_category, wa.i_category, wra.i_category, ca.i_category, cra.i_category) AS category,
    COALESCE(sa.d_year, ra.d_year, wa.d_year, wra.d_year, ca.d_year, cra.d_year) AS sales_year,
    COALESCE(sa.store_profit, 0) - COALESCE(ra.store_return_loss, 0) AS net_store_profit,
    COALESCE(wa.web_profit, 0) - COALESCE(wra.web_return_loss, 0) AS net_web_profit,
    COALESCE(ca.catalog_profit, 0) - COALESCE(cra.catalog_return_loss, 0) AS net_catalog_profit,
    (COALESCE(sa.store_profit, 0) - COALESCE(ra.store_return_loss, 0) +
     COALESCE(wa.web_profit, 0) - COALESCE(wra.web_return_loss, 0) +
     COALESCE(ca.catalog_profit, 0) - COALESCE(cra.catalog_return_loss, 0)) AS total_net_profit,
    (COALESCE(sa.store_qty, 0) - COALESCE(ra.store_ret_qty, 0) +
     COALESCE(wa.web_qty, 0) - COALESCE(wra.web_ret_qty, 0) +
     COALESCE(ca.catalog_qty, 0) - COALESCE(cra.catalog_ret_qty, 0)) AS total_quantity_sold,
    COALESCE(sa.store_cust_cnt, 0) + COALESCE(wa.web_cust_cnt, 0) + COALESCE(ca.catalog_cust_cnt, 0) AS total_distinct_customers
  FROM store_sales_agg sa
  FULL OUTER JOIN store_returns_agg ra ON sa.i_category_id = ra.i_category_id AND sa.d_year = ra.d_year
  FULL OUTER JOIN web_sales_agg wa ON COALESCE(sa.i_category_id, ra.i_category_id) = wa.i_category_id
                                    AND COALESCE(sa.d_year, ra.d_year) = wa.d_year
  FULL OUTER JOIN web_returns_agg wra ON COALESCE(sa.i_category_id, ra.i_category_id, wa.i_category_id) = wra.i_category_id
                                        AND COALESCE(sa.d_year, ra.d_year, wa.d_year) = wra.d_year
  FULL OUTER JOIN catalog_sales_agg ca ON COALESCE(sa.i_category_id, ra.i_category_id, wa.i_category_id, wra.i_category_id) = ca.i_category_id
                                         AND COALESCE(sa.d_year, ra.d_year, wa.d_year, wra.d_year) = ca.d_year
  FULL OUTER JOIN catalog_returns_agg cra ON ca.i_category_id = cra.i_category_id AND ca.d_year = cra.d_year
)
SELECT
  category,
  sales_year,
  total_net_profit,
  net_store_profit,
  net_web_profit,
  net_catalog_profit,
  total_quantity_sold,
  total_distinct_customers,
  RANK() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS profit_rank,
  AVG(total_net_profit) OVER (PARTITION BY category ORDER BY sales_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr_profit,
  SUM(total_net_profit) OVER (PARTITION BY category ORDER BY sales_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_category
FROM combined
WHERE sales_year IS NOT NULL
ORDER BY sales_year, profit_rank
LIMIT 200
