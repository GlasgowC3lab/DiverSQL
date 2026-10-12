WITH brand_hourly AS (
    SELECT
        i.i_brand AS i_brand,
        t.t_hour AS t_hour,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_net_loss) AS sum_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_amt > 0
      AND i.i_brand IS NOT NULL
    GROUP BY i.i_brand, t.t_hour
),
ranked_brands AS (
    SELECT
        i_brand,
        t_hour,
        cnt_returns,
        sum_return_amt,
        avg_return_amt,
        sum_net_loss,
        RANK() OVER (PARTITION BY t_hour ORDER BY sum_return_amt DESC) AS rnk
    FROM brand_hourly
)
SELECT
    i_brand,
    t_hour,
    cnt_returns,
    sum_return_amt,
    avg_return_amt,
    sum_net_loss,
    rnk
FROM ranked_brands
WHERE rnk <= 5
ORDER BY t_hour, rnk
