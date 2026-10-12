SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_month_seq AS end_month_seq,
    MIN(d_ship.d_month_seq) AS ship_month_seq,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_in_period,
    CASE
        WHEN SUM(COALESCE(wr.wr_net_loss, 0)) = 0 THEN NULL
        ELSE SUM(cs.cs_net_profit) / SUM(COALESCE(wr.wr_net_loss, 0))
    END AS profit_to_loss_ratio
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sale
    ON cs.cs_sold_date_sk = d_sale.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN (
    SELECT
        wr.*,
        d_return.d_date AS return_date,
        d_return.d_date_sk AS return_date_sk
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
) wr
    ON wr.wr_returned_date_sk BETWEEN d_start.d_date_sk AND d_end.d_date_sk
LEFT JOIN (
    SELECT
        s.*,
        d_store.d_date AS closed_date,
        d_store.d_date_sk AS closed_date_sk
    FROM store s
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
) s
    ON s.s_closed_date_sk BETWEEN d_start.d_date_sk AND d_end.d_date_sk
WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_start.d_year,
    d_end.d_year,
    d_start.d_month_seq,
    d_end.d_month_seq
ORDER BY total_sales_net_paid DESC
LIMIT 100
