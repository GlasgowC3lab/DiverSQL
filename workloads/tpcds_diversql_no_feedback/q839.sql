WITH sr AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_item_sk,
       sr.sr_store_sk,
       sr.sr_cdemo_sk,
       sr.sr_net_loss,
       d.d_year,
       d.d_month_seq,
       i.i_item_desc,
       i.i_brand,
       s.s_city,
       cd.cd_gender
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE regexp_like(s.s_city, '^New')
     AND i.i_item_desc LIKE '%BRAND%'
)
SELECT
   d_year,
   d_month_seq,
   s_city,
   i_brand,
   COUNT(*) AS returns_count,
   SUM(sr_net_loss) AS total_net_loss,
   CASE
       WHEN SUM(sr_net_loss) > 0 THEN 'Positive Loss'
       WHEN SUM(sr_net_loss) < 0 THEN 'Negative Loss'
       ELSE 'Zero Loss'
   END AS loss_category,
   CONCAT(substr(i_item_desc, 1, 15), '...') AS short_desc
FROM sr
GROUP BY
   d_year,
   d_month_seq,
   s_city,
   i_brand,
   i_item_desc
ORDER BY total_net_loss DESC
LIMIT 100
