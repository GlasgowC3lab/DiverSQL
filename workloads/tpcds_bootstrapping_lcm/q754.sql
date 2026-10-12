WITH joined_data AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_fee,
        wr.wr_order_number,
        dr.d_year,
        dr.d_moy,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_country,
        s.s_market_desc,
        s.s_state,
        w.web_market_manager,
        w.web_state
    FROM web_returns wr
    JOIN date_dim dr
        ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN store s
        ON s.s_closed_date_sk = dr.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = dr.d_date_sk
)
SELECT
    c_birth_year * 100 + c_birth_month AS birth_ym_id,
    d_year,
    d_moy,
    c_birth_country,
    s_market_desc,
    web_market_manager,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr_fee > 0 THEN wr_fee ELSE 0 END) AS total_fees,
    COUNT(DISTINCT wr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns
FROM joined_data
WHERE d_year BETWEEN 2000 AND 2002
GROUP BY
    c_birth_year * 100 + c_birth_month,
    d_year,
    d_moy,
    c_birth_country,
    s_market_desc,
    web_market_manager
HAVING SUM(wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
