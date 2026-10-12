SELECT
    cc.cc_division,
    cc.cc_division_name,
    s.s_division_id,
    s.s_division_name,
    cp.cp_catalog_page_number,
    (d_return.d_year * 100 + d_return.d_month_seq) AS year_month,
    CASE
        WHEN sr.sr_return_quantity >= 10 THEN 'Very Large'
        WHEN sr.sr_return_quantity >= 5 THEN 'Large'
        ELSE 'Small'
    END AS return_qty_category,
    COUNT(*) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    MIN(sr.sr_return_amt) AS min_return_amount,
    MAX(sr.sr_return_amt) AS max_return_amount,
    SUM(sr.sr_fee) AS total_fee
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
WHERE
    cc.cc_tax_percentage > 0.05
    AND s.s_tax_percentage BETWEEN 0.0 AND 0.2
    AND d_return.d_year BETWEEN 2000 AND 2020
GROUP BY
    cc.cc_division,
    cc.cc_division_name,
    s.s_division_id,
    s.s_division_name,
    cp.cp_catalog_page_number,
    (d_return.d_year * 100 + d_return.d_month_seq),
    CASE
        WHEN sr.sr_return_quantity >= 10 THEN 'Very Large'
        WHEN sr.sr_return_quantity >= 5 THEN 'Large'
        ELSE 'Small'
    END
ORDER BY
    total_net_loss DESC
LIMIT 100
