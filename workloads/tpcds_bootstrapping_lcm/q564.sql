SELECT
    rd.d_year AS return_year,
    rd.d_month_seq AS return_month_seq,
    sd.s_state AS store_state,
    ws.web_state AS site_state,
    CASE
        WHEN td.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN td.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN td.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    CASE
        WHEN cd.d_year = rd.d_year THEN 'SameYear'
        ELSE 'DiffYear'
    END AS site_close_year_relation,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_quantity,
    COUNT(*) AS total_rows
FROM web_returns AS wr
JOIN date_dim AS rd
    ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN time_dim AS td
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN store AS sd
    ON sd.s_closed_date_sk = rd.d_date_sk
JOIN web_site AS ws
    ON ws.web_open_date_sk = rd.d_date_sk
JOIN date_dim AS cd
    ON ws.web_close_date_sk = cd.d_date_sk
WHERE rd.d_year BETWEEN 2019 AND 2022
GROUP BY
    rd.d_year,
    rd.d_month_seq,
    sd.s_state,
    ws.web_state,
    CASE
        WHEN td.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN td.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN td.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    CASE
        WHEN cd.d_year = rd.d_year THEN 'SameYear'
        ELSE 'DiffYear'
    END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
