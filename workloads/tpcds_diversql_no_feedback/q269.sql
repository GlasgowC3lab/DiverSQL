WITH base AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_addr_sk,
       sr.sr_return_amt,
       sr.sr_net_loss,
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_net_loss,
       d.d_quarter_seq,
       d.d_year,
       ca.ca_state,
       ca.ca_location_type,
       r.r_reason_desc,
       p.p_promo_name,
       p.p_discount_active,
       p.p_channel_tv,
       wp.wp_char_count
   FROM store_returns sr
   JOIN date_dim d
       ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca
       ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_returns cr
       ON cr.cr_returned_date_sk = d.d_date_sk
          AND cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN web_page wp
       ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN promotion p
       ON p.p_start_date_sk = d.d_date_sk
),
filtered AS (
   SELECT *
   FROM base
   WHERE d_year = 2000
     AND ca_state = 'CA'
     AND p_discount_active = 'Y'
     AND p_channel_tv = 'Y'
     AND r_reason_desc = 'Damaged'
     AND wp_char_count > 3000
     AND sr_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_location_type = 'apartment')
),
agg1 AS (
   SELECT
       d_quarter_seq,
       p_promo_name,
       SUM(sr_return_amt + cr_return_amount) AS total_return_amount,
       SUM(sr_net_loss + cr_net_loss) AS total_net_loss,
       COUNT(*) AS cnt
   FROM filtered
   WHERE wp_char_count > 3500
   GROUP BY d_quarter_seq, p_promo_name
),
agg2 AS (
   SELECT
       d_quarter_seq,
       p_promo_name,
       SUM(sr_return_amt + cr_return_amount) AS total_return_amount,
       SUM(sr_net_loss + cr_net_loss) AS total_net_loss,
       COUNT(*) AS cnt
   FROM filtered
   WHERE wp_char_count <= 3500
   GROUP BY d_quarter_seq, p_promo_name
),
unioned AS (
   SELECT * FROM agg1
   UNION DISTINCT
   SELECT * FROM agg2
)
SELECT
   d_quarter_seq,
   p_promo_name,
   SUM(total_return_amount) AS sum_return_amount,
   AVG(total_net_loss) AS avg_net_loss,
   SUM(cnt) AS total_returns
FROM unioned
GROUP BY d_quarter_seq, p_promo_name
HAVING AVG(total_net_loss) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100
