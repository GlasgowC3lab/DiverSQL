WITH store_active AS (
    SELECT s_store_sk, s_state, s_country, s_tax_percentage, s_store_name, s_city
    FROM store
    WHERE s_closed_date_sk IS NULL
      AND s_rec_start_date <= DATE '2023-01-01'
      AND (s_rec_end_date IS NULL OR s_rec_end_date >= DATE '2023-01-01')
),
website_active AS (
    SELECT web_site_sk, web_state, web_country, web_tax_percentage, web_name, web_city
    FROM web_site
    WHERE web_close_date_sk IS NULL
      AND web_rec_start_date <= DATE '2023-01-01'
      AND (web_rec_end_date IS NULL OR web_rec_end_date >= DATE '2023-01-01')
),
store_reason AS (
    SELECT s.s_store_sk,
           s.s_state,
           s.s_country,
           s.s_tax_percentage,
           r.r_reason_desc
    FROM store_active s
    LEFT JOIN reason r
      ON s.s_store_sk = r.r_reason_sk
)
SELECT sr.s_state,
       sr.s_country,
       COUNT(DISTINCT sr.s_store_sk) AS active_store_cnt,
       COUNT(DISTINCT w.web_site_sk) AS active_website_cnt,
       ROUND(AVG(sr.s_tax_percentage), 2) AS avg_store_tax,
       ROUND(AVG(w.web_tax_percentage), 2) AS avg_website_tax,
       ROUND((AVG(sr.s_tax_percentage) + AVG(w.web_tax_percentage)) / 2, 2) AS avg_combined_tax,
       (
           SELECT r2.r_reason_desc
           FROM reason r2
           JOIN store s2 ON s2.s_store_sk = r2.r_reason_sk
           WHERE s2.s_state = sr.s_state
           GROUP BY r2.r_reason_desc
           ORDER BY COUNT(*) DESC
           LIMIT 1
       ) AS top_reason_desc
FROM store_reason sr
JOIN website_active w
  ON sr.s_state = w.web_state
 AND sr.s_country = w.web_country
GROUP BY sr.s_state, sr.s_country
HAVING COUNT(DISTINCT sr.s_store_sk) >= 5
ORDER BY avg_combined_tax DESC
LIMIT 10
