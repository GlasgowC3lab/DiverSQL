WITH store_daily AS (
   SELECT d.d_date,
          'store' AS channel,
          SUM(sr.sr_net_loss) AS daily_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE EXISTS (
       SELECT 1
       FROM web_returns wr
       JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
       WHERE wr.wr_item_sk = sr.sr_item_sk
         AND d2.d_date = d.d_date
   )
   GROUP BY d.d_date
),
web_daily AS (
   SELECT d.d_date,
          'web' AS channel,
          SUM(wr.wr_net_loss) AS daily_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE EXISTS (
       SELECT 1
       FROM store_returns sr
       JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
       WHERE sr.sr_item_sk = wr.wr_item_sk
         AND d2.d_date = d.d_date
   )
   GROUP BY d.d_date
),
all_daily AS (
   SELECT * FROM store_daily
   UNION ALL
   SELECT * FROM web_daily
),
weekend_daily AS (
   SELECT ad.d_date,
          ad.channel,
          ad.daily_loss
   FROM all_daily ad
   JOIN date_dim d ON ad.d_date = d.d_date
   WHERE d.d_dow IN (0, 6)   -- Sunday (0) and Saturday (6)
),
diff_daily AS (
   SELECT * FROM all_daily
   EXCEPT
   SELECT * FROM weekend_daily
)
SELECT
    d.d_year,
    d.d_month_seq,
    t.channel,
    SUM(t.daily_loss) AS total_loss
FROM (
    SELECT ad.d_date,
           ad.channel,
           ad.daily_loss
    FROM diff_daily ad
) t
JOIN date_dim d ON t.d_date = d.d_date
GROUP BY ROLLUP (d.d_year, d.d_month_seq, t.channel)
ORDER BY d.d_year, d.d_month_seq, t.channel
LIMIT 100
