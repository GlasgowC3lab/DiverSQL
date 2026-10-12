WITH filtered_dates AS (
   SELECT d_date_sk,
          d_date,
          d_day_name,
          d_holiday,
          substring(d_day_name, 1, 3) AS day_prefix,
          CASE WHEN regexp_like(d_holiday, '.*Day.*') THEN 1 ELSE 0 END AS has_day_holiday,
          concat(d_day_name, '_', d_holiday) AS day_holiday_key
   FROM date_dim
   WHERE d_year = 2001
     AND d_holiday LIKE '%Day%'
),
store_credit_keys AS (
   SELECT sr_store_sk
   FROM store_returns
   WHERE sr_store_credit > 100
   INTERSECT
   SELECT sr_store_sk
   FROM store_returns
   WHERE sr_store_credit < 5
),
agg_returns AS (
   SELECT fd.d_day_name,
          COUNT(*) AS total_returns,
          SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
          AVG(sr.sr_return_tax) AS avg_tax,
          SUM(CASE WHEN regexp_like(fd.d_holiday, '^.*[Hh]oliday$') THEN 1 ELSE 0 END) AS holiday_returns
   FROM filtered_dates fd
   JOIN store_returns sr
     ON sr.sr_returned_date_sk = fd.d_date_sk
   WHERE sr.sr_store_sk IN (SELECT sr_store_sk FROM store_credit_keys)
   GROUP BY fd.d_day_name
)
SELECT *
FROM (
   SELECT d_day_name,
          total_returns,
          total_return_amount,
          avg_tax,
          holiday_returns
   FROM agg_returns
   UNION
   SELECT d_day_name,
          total_returns,
          total_return_amount,
          avg_tax,
          holiday_returns
   FROM (
       SELECT d.d_day_name,
              COUNT(*) AS total_returns,
              SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
              AVG(sr.sr_return_tax) AS avg_tax,
              SUM(CASE WHEN regexp_like(d.d_holiday, '^.*[Hh]oliday$') THEN 1 ELSE 0 END) AS holiday_returns
       FROM date_dim d
       JOIN store_returns sr
         ON sr.sr_returned_date_sk = d.d_date_sk
       WHERE d.d_weekend = 'Y'
         AND sr.sr_return_amt_inc_tax > 200
       GROUP BY d.d_day_name
   ) AS weekend_agg
) AS combined
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
