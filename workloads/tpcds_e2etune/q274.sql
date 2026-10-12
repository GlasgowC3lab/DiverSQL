WITH cs_monthly AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(cs.cs_net_profit) AS total_cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND cs.cs_warehouse_sk = 3
  GROUP BY d.d_year, d.d_month_seq
),
ws AS (
  SELECT ws_order_number,
         ws_item_sk,
         ws_net_profit
  FROM web_sales
),
wr AS (
  SELECT wr_returned_date_sk,
         wr_order_number,
         wr_item_sk,
         wr_reason_sk,
         wr_return_amt_inc_tax,
         wr_net_loss,
         wr_return_quantity
  FROM web_returns
  WHERE wr_return_quantity > 1
),
returns_detail AS (
  SELECT d_ret.d_year,
         d_ret.d_month_seq,
         r.r_reason_desc,
         SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
         SUM(wr.wr_net_loss) AS total_net_loss,
         COUNT(*) AS return_cnt,
         AVG(wr.wr_return_quantity) AS avg_return_qty,
         SUM(ws.ws_net_profit) AS total_original_net_profit
  FROM wr
  JOIN ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d_ret.d_year = 2020
  GROUP BY d_ret.d_year, d_ret.d_month_seq, r.r_reason_desc
),
joined AS (
  SELECT rd.d_year,
         rd.d_month_seq,
         rd.r_reason_desc,
         rd.total_return_amount,
         rd.total_net_loss,
         rd.return_cnt,
         rd.avg_return_qty,
         rd.total_original_net_profit,
         cs.total_cs_net_profit
  FROM returns_detail rd
  LEFT JOIN cs_monthly cs
    ON rd.d_year = cs.d_year
   AND rd.d_month_seq = cs.d_month_seq
),
ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rnk
  FROM joined
)
SELECT d_year,
       d_month_seq,
       r_reason_desc,
       total_return_amount,
       total_net_loss,
       return_cnt,
       avg_return_qty,
       total_original_net_profit,
       total_cs_net_profit,
       rnk
FROM ranked
WHERE rnk <= 5
ORDER BY d_year, rnk
