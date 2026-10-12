WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        c.c_email_address,
        d.d_year,
        d.d_month_seq
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND c.c_email_address LIKE '%@example.com'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    SUM(fs.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CONCAT(
        REGEXP_EXTRACT(fs.c_email_address, '([^@]+)@'),
        '_',
        CAST(d.d_month_seq AS varchar)
    ) AS email_month_key
FROM filtered_sales fs
JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
JOIN date_dim d  ON fs.ss_sold_date_sk = d.d_date_sk
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    REGEXP_EXTRACT(fs.c_email_address, '([^@]+)@')
ORDER BY total_profit DESC, sales_cnt DESC
LIMIT 100
