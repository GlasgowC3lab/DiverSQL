SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_market_desc,
    COUNT(DISTINCT wr.wr_order_number) AS return_orders,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
FROM catalog_page cp
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
WHERE d_start.d_year >= 2020
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_market_desc
ORDER BY total_net_loss DESC
LIMIT 100
