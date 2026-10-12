WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        SUM(cs.cs_net_profit) AS total_cs_net_profit,
        COUNT(*) AS cs_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, d_sold.d_year, d_sold.d_month_seq
),
ws_agg AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        COUNT(*) AS ws_txn_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, d_sold.d_year, d_sold.d_month_seq
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_item_sk AS item_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS wr_txn_cnt,
        SUM(ws.ws_net_paid) AS total_returned_ws_net_paid,
        SUM(ws.ws_net_profit) AS total_returned_ws_net_profit
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    COALESCE(cs.item_sk, ws.item_sk, wr.item_sk) AS item_sk,
    COALESCE(cs.total_cs_net_paid, 0) AS total_catalog_net_paid,
    COALESCE(ws.total_ws_net_paid, 0) AS total_web_net_paid,
    COALESCE(wr.total_return_amount, 0) AS total_return_amount,
    COALESCE(wr.total_returned_ws_net_paid, 0) AS total_returned_ws_net_paid,
    (COALESCE(cs.total_cs_net_paid, 0) + COALESCE(ws.total_ws_net_paid, 0) - COALESCE(wr.total_return_amount, 0)) AS net_sales,
    (COALESCE(cs.total_cs_net_profit, 0) + COALESCE(ws.total_ws_net_profit, 0) - COALESCE(wr.total_return_loss, 0) - COALESCE(wr.total_returned_ws_net_profit, 0)) AS net_profit,
    RANK() OVER (ORDER BY (COALESCE(cs.total_cs_net_paid, 0) + COALESCE(ws.total_ws_net_paid, 0) - COALESCE(wr.total_return_amount, 0)) DESC) AS sales_rank
FROM store s
JOIN date_dim d
  ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN cs_agg cs
  ON cs.sold_date_sk = d.d_date_sk
LEFT JOIN ws_agg ws
  ON ws.sold_date_sk = d.d_date_sk
LEFT JOIN wr_agg wr
  ON wr.returned_date_sk = d.d_date_sk
ORDER BY net_sales DESC
LIMIT 100
