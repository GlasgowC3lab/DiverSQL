WITH
  purchases AS (
    SELECT 
      c.c_customer_id,
      c.c_customer_sk,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(DISTINCT ss.ss_store_sk) AS store_visits,
      COUNT(t.channel) AS promo_channel_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN UNNEST(split(coalesce(p.p_channel_details, ''), ',')) AS t(channel) ON true
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, c.c_customer_sk
    HAVING SUM(ss.ss_net_paid) > 1000
  ),
  returns AS (
    SELECT 
      c.c_customer_id,
      c.c_customer_sk,
      SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, c.c_customer_sk
    HAVING SUM(wr.wr_return_amt) > 0
  ),
  filtered_customers AS (
    SELECT 
      p.c_customer_id,
      p.total_net_paid,
      p.store_visits,
      p.promo_channel_count,
      (
        SELECT COUNT(DISTINCT ss3.ss_store_sk)
        FROM store_sales ss3
        JOIN customer c3 ON ss3.ss_customer_sk = c3.c_customer_sk
        WHERE c3.c_customer_id = p.c_customer_id
      ) AS distinct_store_count
    FROM purchases p
    EXCEPT
    SELECT 
      r.c_customer_id,
      r.total_return_amt,
      NULL,
      NULL,
      NULL
    FROM returns r
  )
SELECT 
  fc.c_customer_id,
  fc.total_net_paid,
  fc.distinct_store_count,
  fc.store_visits,
  fc.promo_channel_count
FROM filtered_customers fc
ORDER BY fc.total_net_paid DESC
LIMIT 100
