SELECT
    cp.cp_department,
    i.i_category,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    d_end.d_year AS catalog_end_year,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(i.i_current_price * wr.wr_return_quantity) AS total_item_price,
    SUM(wr.wr_return_amt) / NULLIF(SUM(i.i_current_price * wr.wr_return_quantity), 0) AS return_price_ratio,
    AVG(wr.wr_fee) AS avg_fee,
    CASE
        WHEN d_return.d_year = d_end.d_year THEN 'SameYear'
        ELSE 'DiffYear'
    END AS year_match
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_return.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE wr.wr_return_quantity > 0
GROUP BY
    cp.cp_department,
    i.i_category,
    d_return.d_year,
    d_return.d_month_seq,
    d_end.d_year
ORDER BY total_return_amount DESC
LIMIT 50
