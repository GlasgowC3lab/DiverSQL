WITH daily_item_returns AS (
    SELECT
        d.d_date_id,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        SUM(wr.wr_return_quantity) AS total_qty,
        SUM(wr.wr_return_amt) AS total_amt,
        AVG(wr.wr_fee) AS avg_fee
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = wr.wr_item_sk
    GROUP BY d.d_date_id, d.d_year, d.d_month_seq, i.i_item_sk, i.i_category, i.i_brand
),
store_closure AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_date_id,
        d.d_year,
        d.d_month_seq
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    di.d_date_id,
    di.d_year,
    di.i_category,
    di.i_brand,
    sc.s_store_name,
    sc.s_state,
    di.total_qty,
    di.total_amt,
    di.avg_fee,
    ROW_NUMBER() OVER (PARTITION BY di.d_year ORDER BY di.total_amt DESC) AS rank_in_year
FROM daily_item_returns di
JOIN store_closure sc ON sc.d_date_id = di.d_date_id
WHERE di.d_year BETWEEN 2000 AND 2005
ORDER BY di.d_date_id
LIMIT 100
