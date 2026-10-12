WITH promo_start AS (
    SELECT p.p_promo_sk,
           p.p_item_sk,
           p.p_cost,
           p.p_promo_name,
           d_start.d_fy_year,
           d_start.d_fy_quarter_seq,
           d_start.d_quarter_name,
           d_end.d_date AS end_date
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_fy_year = 2020
      AND d_end.d_fy_year = 2020
)
SELECT i.i_brand,
       ps.d_fy_quarter_seq AS quarter_seq,
       COUNT(DISTINCT ps.p_promo_sk) AS promo_count,
       COUNT(DISTINCT ps.p_item_sk) AS distinct_items,
       SUM(ps.p_cost) AS total_promo_cost,
       AVG(ps.p_cost) AS avg_promo_cost
FROM promo_start ps
JOIN item i ON ps.p_item_sk = i.i_item_sk
GROUP BY i.i_brand, ps.d_fy_quarter_seq
ORDER BY total_promo_cost DESC
LIMIT 10
