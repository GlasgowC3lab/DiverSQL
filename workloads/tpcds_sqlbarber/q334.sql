SELECT
    d.d_year,
    s.s_store_name,
    SUM(ss.ss_net_paid) AS total_sales,
    sub.total_return_amt
FROM
    store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN (
        SELECT
            sr.sr_store_sk,
            sr.sr_returned_date_sk,
            SUM(sr.sr_return_amt) AS total_return_amt
        FROM
            store_returns sr
        GROUP BY
            sr.sr_store_sk,
            sr.sr_returned_date_sk
    ) sub ON sub.sr_store_sk = s.s_store_sk
    AND sub.sr_returned_date_sk = d.d_date_sk
WHERE
    d.d_year = 1918
    AND s.s_state = 'TN'
GROUP BY
    d.d_year,
    s.s_store_name,
    sub.total_return_amt
HAVING
    SUM(ss.ss_net_paid) > 1456.94
