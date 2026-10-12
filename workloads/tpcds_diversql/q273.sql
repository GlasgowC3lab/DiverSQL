WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_store_sk,
    ss.ss_net_paid,
    s.s_store_name,
    s.s_city,
    s.s_zip,
    d.d_date,
    p.p_promo_name,
    split(p.p_promo_name, ' ') AS words
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2002
    AND regexp_like(s.s_store_name, '^Store [A-M]')
    AND s.s_city LIKE '%York%'
),
expanded AS (
  SELECT
    b.ss_store_sk,
    b.s_store_name,
    b.s_city,
    b.s_zip,
    b.d_date,
    b.ss_net_paid,
    b.p_promo_name,
    t.word
  FROM base b
  CROSS JOIN UNNEST(b.words) AS t(word)
  WHERE t.word <> ''
),
final_agg AS (
  SELECT
    e.ss_store_sk,
    e.s_store_name,
    substring(e.s_zip, 1, 5) AS zip_prefix,
    regexp_extract(e.p_promo_name, '(PROMO[0-9]+)', 1) AS promo_code,
    e.word,
    COUNT(*) AS sale_rows,
    SUM(e.ss_net_paid) AS total_net_paid
  FROM expanded e
  GROUP BY
    e.ss_store_sk,
    e.s_store_name,
    substring(e.s_zip, 1, 5),
    regexp_extract(e.p_promo_name, '(PROMO[0-9]+)', 1),
    e.word
),
final AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY total_net_paid DESC) AS rn
  FROM final_agg
)
SELECT *
FROM final
ORDER BY total_net_paid DESC
LIMIT 100
