WITH cat_sales_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit_amount
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
store_sales_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
web_sales_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit_amount
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
cat_returns_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
store_returns_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_net_loss) AS return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
web_returns_agg AS (
 SELECT d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(wr.wr_net_loss) AS return_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_quarter_seq, ca.ca_state, i.i_category
),
all_sales AS (
 SELECT year, quarter_seq, state, category, sales_amount, profit_amount, CAST(0 AS DECIMAL(15,2)) AS return_amount, CAST(0 AS DECIMAL(15,2)) AS return_loss FROM cat_sales_agg
 UNION ALL
 SELECT year, quarter_seq, state, category, sales_amount, profit_amount, CAST(0 AS DECIMAL(15,2)), CAST(0 AS DECIMAL(15,2)) FROM store_sales_agg
 UNION ALL
 SELECT year, quarter_seq, state, category, sales_amount, profit_amount, CAST(0 AS DECIMAL(15,2)), CAST(0 AS DECIMAL(15,2)) FROM web_sales_agg
 UNION ALL
 SELECT year, quarter_seq, state, category, CAST(0 AS DECIMAL(15,2)), CAST(0 AS DECIMAL(15,2)), return_amount, return_loss FROM cat_returns_agg
 UNION ALL
 SELECT year, quarter_seq, state, category, CAST(0 AS DECIMAL(15,2)), CAST(0 AS DECIMAL(15,2)), return_amount, return_loss FROM store_returns_agg
 UNION ALL
 SELECT year, quarter_seq, state, category, CAST(0 AS DECIMAL(15,2)), CAST(0 AS DECIMAL(15,2)), return_amount, return_loss FROM web_returns_agg
),
agg_sales AS (
 SELECT year,
        quarter_seq,
        state,
        category,
        SUM(sales_amount) AS total_sales_amount,
        SUM(profit_amount) AS total_profit_amount,
        SUM(return_amount) AS total_return_amount,
        SUM(return_loss) AS total_return_loss
 FROM all_sales
 WHERE year BETWEEN 1999 AND 2002
 GROUP BY year, quarter_seq, state, category
)
SELECT
  year,
  quarter_seq,
  state,
  category,
  total_sales_amount,
  total_profit_amount,
  total_return_amount,
  total_return_loss,
  total_profit_amount - total_return_loss AS net_profit_after_returns,
  SUM(total_sales_amount) OVER (PARTITION BY state ORDER BY year, quarter_seq ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS sales_last_4_quarters,
  RANK() OVER (PARTITION BY year ORDER BY total_sales_amount DESC) AS sales_state_rank
FROM agg_sales
ORDER BY year, quarter_seq, total_sales_amount DESC
LIMIT 200
