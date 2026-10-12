WITH daily_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_month_seq % 12 + 1 AS month_num,
        t.t_hour,
        CASE 
            WHEN t.t_hour BETWEEN 5 AND 11 THEN 'Morning'
            WHEN t.t_hour BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN t.t_hour BETWEEN 17 AND 20 THEN 'Evening'
            ELSE 'Night'
        END AS time_bucket,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY cs.cs_sold_date_sk, d.d_date, d.d_year, d.d_month_seq, t.t_hour,
        CASE 
            WHEN t.t_hour BETWEEN 5 AND 11 THEN 'Morning'
            WHEN t.t_hour BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN t.t_hour BETWEEN 17 AND 20 THEN 'Evening'
            ELSE 'Night'
        END
)
SELECT
    ds.d_date,
    ds.d_year,
    ds.time_bucket,
    ds.total_net_paid,
    ds.total_net_profit,
    ds.avg_discount,
    RANK() OVER (PARTITION BY ds.d_year, ds.month_num ORDER BY ds.total_net_paid DESC) AS rank_in_month,
    SUM(ds.total_net_paid) OVER (PARTITION BY ds.d_year ORDER BY ds.d_date) AS cumulative_year_net_paid,
    ws.web_site_id,
    ws.web_name
FROM daily_sales ds
JOIN web_site ws
  ON ds.cs_sold_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
ORDER BY ds.d_date, ds.time_bucket
