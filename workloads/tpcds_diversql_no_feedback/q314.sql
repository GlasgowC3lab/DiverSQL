WITH store_ret AS (
    SELECT
        d.d_date AS return_date,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_date
),
web_ret AS (
    SELECT
        d.d_date AS return_date,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_date
),
catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_city = 'Riverside'
    GROUP BY d.d_date
)
SELECT
    ROW_NUMBER() OVER (ORDER BY return_date, channel) AS row_num,
    return_date,
    channel,
    total_net_loss,
    return_cnt
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
    UNION ALL
    SELECT * FROM catalog_ret
) AS combined
ORDER BY return_date, channel
