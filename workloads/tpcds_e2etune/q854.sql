WITH promo_discount_by_state_month AS (
    SELECT
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        p.p_promo_sk,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ca.ca_country = 'United States'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq, p.p_promo_sk
),
ranked_promos AS (
    SELECT
        ca_state,
        d_year,
        d_month_seq,
        p_promo_sk,
        total_discount,
        ROW_NUMBER() OVER (PARTITION BY ca_state, d_year, d_month_seq ORDER BY total_discount DESC) AS promo_rank
    FROM promo_discount_by_state_month
)
SELECT
    ca.ca_state AS ca_state,
    d.d_year AS d_year,
    d.d_month_seq AS d_month_seq,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT ss.ss_promo_sk) AS distinct_promo_cnt,
    MAX(CASE WHEN rp.promo_rank = 1 THEN rp.total_discount END) AS top_promo_discount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN ranked_promos rp
    ON ca.ca_state = rp.ca_state
    AND d.d_year = rp.d_year
    AND d.d_month_seq = rp.d_month_seq
    AND ss.ss_promo_sk = rp.p_promo_sk
WHERE ca.ca_country = 'United States'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY ca.ca_state, d.d_year, d.d_month_seq
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
