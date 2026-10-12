WITH
  promo_words AS (
    SELECT
      p.p_promo_sk,
      word
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_channel_details, ' ')) AS t(word)
    WHERE regexp_like(word, '^[A-Z][a-z]+$')
  ),
  customer_eligible AS (
    SELECT
      c.c_customer_sk,
      concat(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
      c.c_birth_country
    FROM customer c
    WHERE lower(c.c_birth_country) LIKE '%islands%'
  ),
  store_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      sum(ss.ss_net_profit) AS total_net_profit,
      count(*) AS total_transactions
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_net_profit > 0
    GROUP BY s.s_store_sk, s.s_store_name
  ),
  intersect_keys AS (
    SELECT c.c_customer_sk AS key_id FROM customer_eligible c
    INTERSECT
    SELECT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_net_profit > 0
  )
SELECT
  COALESCE(sa.s_store_sk, pw.p_promo_sk) AS entity_id,
  regexp_extract(sa.s_store_name, '(\\w+)', 1) AS store_first_word,
  substr(sa.s_store_name, 1, 5) AS store_prefix,
  pw.word,
  sa.total_net_profit,
  sa.total_transactions
FROM store_agg sa
FULL OUTER JOIN (
  SELECT p_promo_sk, word FROM promo_words
) pw
ON sa.s_store_sk = pw.p_promo_sk
WHERE COALESCE(sa.s_store_sk, pw.p_promo_sk) IN (SELECT key_id FROM intersect_keys)
ORDER BY sa.total_net_profit DESC NULLS LAST, entity_id
