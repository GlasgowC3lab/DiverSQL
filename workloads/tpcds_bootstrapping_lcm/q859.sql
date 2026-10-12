SELECT
    cp.cp_department,
    cp.cp_type,
    dsold.d_year AS sold_year,
    dship.d_month_seq AS ship_month,
    dpage_start.d_date AS page_start_date,
    dpage_end.d_date AS page_end_date,
    s.s_store_id,
    s.s_city,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dsold
    ON cs.cs_sold_date_sk = dsold.d_date_sk
JOIN date_dim dship
    ON cs.cs_ship_date_sk = dship.d_date_sk
JOIN date_dim dpage_start
    ON cp.cp_start_date_sk = dpage_start.d_date_sk
JOIN date_dim dpage_end
    ON cp.cp_end_date_sk = dpage_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dsold.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dpage_end.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    dsold.d_year,
    dship.d_month_seq,
    dpage_start.d_date,
    dpage_end.d_date,
    s.s_store_id,
    s.s_city,
    s.s_state
ORDER BY net_profit_after_returns DESC
LIMIT 100
