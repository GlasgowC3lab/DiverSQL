WITH store_return_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_date AS closed_return_date,
        d.d_year,
        d.d_month_seq,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_fee) AS total_fees
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_date,
        d.d_year,
        d.d_month_seq
    HAVING COUNT(*) > 5
)
SELECT
    sra.s_store_id,
    sra.s_store_name,
    sra.s_city,
    sra.closed_return_date,
    sra.d_year,
    sra.d_month_seq,
    sra.total_returns,
    sra.total_return_amount,
    sra.total_net_loss,
    sra.avg_return_quantity,
    sra.total_return_amount_inc_tax,
    sra.total_return_tax,
    sra.total_fees,
    CASE
        WHEN sra.total_return_amount > 10000 THEN 'Very High'
        WHEN sra.total_return_amount > 5000 THEN 'High'
        ELSE 'Moderate'
    END AS return_amount_category,
    RANK() OVER (PARTITION BY sra.s_store_id ORDER BY sra.total_return_amount DESC) AS return_amount_rank_by_store,
    sra.total_return_amount / NULLIF(sra.total_returns, 0) AS avg_return_amount_per_return
FROM store_return_agg sra
ORDER BY sra.total_return_amount DESC
LIMIT 100
