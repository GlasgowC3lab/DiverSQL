WITH filtered_returns AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_item_id,
    regexp_extract(i.i_item_desc, '(?i)(pink\\w*)', 1) AS pink_word,
    p.p_promo_name,
    sr.sr_net_loss
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '(?i)pink')
    AND p.p_promo_name LIKE '%Summer%'
)
SELECT
  d_year,
  d_moy,
  i_item_id,
  pink_word,
  p_promo_name,
  concat(i_item_id, '-', p_promo_name) AS item_promo_key,
  sum(sr_net_loss) AS total_net_loss
FROM filtered_returns
GROUP BY d_year, d_moy, i_item_id, pink_word, p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
