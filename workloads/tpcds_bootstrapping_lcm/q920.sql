SELECT
    s.s_store_id,
    s.s_city,
    d_return.d_year,
    floor((d_return.d_month_seq - 1) / 3) + 1 AS quarter,
    cd_returning.cd_gender || '_' || cd_returning.cd_marital_status AS gender_marital,
    CASE
        WHEN d_store_close.d_year < d_return.d_year THEN 'ClosedBefore'
        WHEN d_store_close.d_year = d_return.d_year THEN 'ClosedSameYear'
        ELSE 'ClosedAfter'
    END AS store_closed_relative,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cd_refunded.cd_education_status) AS unique_refunded_education_statuses,
    SUM(CASE WHEN cd_returning.cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END) AS excellent_credit_count,
    SUM(CASE WHEN cd_returning.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_count
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
CROSS JOIN store s
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
WHERE d_return.d_year = 2022
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_return.d_year,
    floor((d_return.d_month_seq - 1) / 3) + 1,
    cd_returning.cd_gender || '_' || cd_returning.cd_marital_status,
    CASE
        WHEN d_store_close.d_year < d_return.d_year THEN 'ClosedBefore'
        WHEN d_store_close.d_year = d_return.d_year THEN 'ClosedSameYear'
        ELSE 'ClosedAfter'
    END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY s.s_store_id, d_return.d_year, quarter
