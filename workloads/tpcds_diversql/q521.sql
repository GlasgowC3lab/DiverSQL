WITH store_ret AS (
   SELECT
       sr.sr_customer_sk,
       s.s_store_id,
       i.i_item_id,
       i.i_product_name,
       sr.sr_net_loss,
       sr.sr_return_amt,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
       CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_status,
       i.i_item_id AS original_item_id
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE regexp_like(i.i_product_name, '(?i)deluxe|premium')
     AND s.s_store_name LIKE 'A%'
     AND EXISTS (
         SELECT 1 FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_discount_active = 'Y'
     )
),

lateral_item AS (
   SELECT
       sr.*,
       extracted.item_numeric
   FROM store_ret sr
   CROSS JOIN LATERAL (
        SELECT CAST(regexp_extract(original_item_id, '\\d+') AS integer) AS item_numeric
   ) extracted
),

max_income AS (
   SELECT MAX(ib_upper_bound) AS max_ub FROM income_band
),

store_customers AS (
   SELECT DISTINCT sr_customer_sk FROM store_returns
),

web_customers AS (
   SELECT DISTINCT wr_returning_customer_sk FROM web_returns
),

store_only_customers AS (
   SELECT c.c_customer_sk, c.c_email_address
   FROM customer c
   WHERE c.c_customer_sk IN (SELECT sr_customer_sk FROM store_customers)
     AND c.c_customer_sk NOT IN (SELECT wr_returning_customer_sk FROM web_customers)
),

final AS (
   SELECT
       customer_name,
       s_store_id,
       i_item_id,
       item_numeric,
       sr_return_amt,
       sr_net_loss,
       loss_status,
       CASE
         WHEN sr_net_loss > (SELECT max_ub FROM max_income) THEN 'High Loss'
         ELSE 'Normal Loss'
       END AS loss_category,
       SUBSTRING(i_item_id, 1, 3) AS item_prefix
   FROM lateral_item
   WHERE item_numeric > (SELECT MIN(ib_lower_bound) FROM income_band)
)

SELECT
    customer_name,
    s_store_id,
    i_item_id,
    item_numeric,
    sr_return_amt,
    sr_net_loss,
    loss_status,
    loss_category,
    item_prefix
FROM final
WHERE customer_name LIKE '%Smith%'
EXCEPT
SELECT
    customer_name,
    s_store_id,
    i_item_id,
    item_numeric,
    sr_return_amt,
    sr_net_loss,
    loss_status,
    loss_category,
    item_prefix
FROM final
WHERE loss_status = 'Gain'
LIMIT 100
