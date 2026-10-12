WITH recent_sales AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       i.i_item_id,
       s.s_store_name,
       ss.ss_net_paid_inc_tax
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2452580 AND 2452629
),
promo_sales AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       i.i_item_id,
       s.s_store_name,
       ss.ss_net_paid_inc_tax
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2452580 AND 2452629
     AND p.p_discount_active = 'Y'
)
SELECT diff.ss_ticket_number,
       diff.ss_sold_date_sk,
       diff.i_item_id,
       diff.s_store_name,
       diff.ss_net_paid_inc_tax
FROM (
   SELECT ss_ticket_number, ss_sold_date_sk, i_item_id, s_store_name, ss_net_paid_inc_tax
   FROM recent_sales
   EXCEPT
   SELECT ss_ticket_number, ss_sold_date_sk, i_item_id, s_store_name, ss_net_paid_inc_tax
   FROM promo_sales
) AS diff
WHERE diff.i_item_id NOT IN (
   SELECT i_item_id
   FROM item
   WHERE i_color = 'Red'
)
ORDER BY diff.ss_net_paid_inc_tax DESC
LIMIT 100
