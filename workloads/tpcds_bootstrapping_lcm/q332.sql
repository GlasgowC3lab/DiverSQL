WITH sales_returns AS (
    SELECT
        s.s_store_id,
        dt_sold.d_year AS sale_year,
        dt_sold.d_month_seq AS sale_month,
        dt_ship.d_moy AS ship_month,
        r.r_reason_desc AS r_reason_desc,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_sales_net,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(cs.cs_net_paid) / NULLIF(SUM(wr.wr_return_amt), 0) AS net_to_return_ratio
    FROM catalog_sales cs
    JOIN date_dim dt_sold
        ON cs.cs_sold_date_sk = dt_sold.d_date_sk
    JOIN date_dim dt_ship
        ON cs.cs_ship_date_sk = dt_ship.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = dt_sold.d_date_sk
    JOIN date_dim dt_return
        ON wr.wr_returned_date_sk = dt_return.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = dt_return.d_date_sk
    GROUP BY
        s.s_store_id,
        dt_sold.d_year,
        dt_sold.d_month_seq,
        dt_ship.d_moy,
        r.r_reason_desc
)
SELECT
    s_store_id,
    sale_year,
    sale_month,
    ship_month,
    r_reason_desc,
    order_cnt,
    total_sales_net,
    total_discount,
    total_return_amt,
    total_return_loss,
    net_to_return_ratio,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales_net DESC) AS sales_rank
FROM sales_returns
WHERE total_sales_net > 5000
ORDER BY total_sales_net DESC
LIMIT 100
