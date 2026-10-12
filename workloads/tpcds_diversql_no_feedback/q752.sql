WITH combined AS (
   SELECT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       s.s_store_name,
       i.i_item_id,
       COALESCE(r.r_reason_desc, 'No Reason') AS reason_desc,
       SUM(COALESCE(cr.cr_return_quantity, 0)) AS catalog_return_qty,
       SUM(COALESCE(sr.sr_return_quantity, 0)) AS store_return_qty,
       SUM(COALESCe(cr.cr_net_loss, 0)) AS catalog_net_loss,
       SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
   FROM store_sales ss
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca
       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = ss.ss_item_sk
      AND sr.sr_customer_sk = ss.ss_customer_sk
      AND sr.sr_store_sk = ss.ss_store_sk
   LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_refunded_customer_sk = c.c_customer_sk
      AND cr.cr_refunded_addr_sk = ca.ca_address_sk
   WHERE i.i_current_price BETWEEN 50 AND 1000
     AND s.s_country = 'United States'
     AND s.s_floor_space > 6000000
     AND c.c_salutation = 'Mr.'
     AND ss.ss_net_profit > 0
     AND s.s_rec_start_date >= DATE '2000-01-01'
     AND (r.r_reason_desc LIKE '%Defect%' OR r.r_reason_desc IS NULL)
     AND (cr.cr_return_quantity > 1 OR cr.cr_return_quantity IS NULL)
     AND (sr.sr_return_quantity >= 1 OR sr.sr_return_quantity IS NULL)
   GROUP BY
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       s.s_store_name,
       i.i_item_id,
       COALESCE(r.r_reason_desc, 'No Reason')
)
SELECT DISTINCT
   c_customer_id,
   c_first_name,
   c_last_name,
   s_store_name,
   i_item_id,
   reason_desc,
   (catalog_return_qty + store_return_qty) AS total_return_qty,
   (catalog_net_loss + store_net_loss) AS total_net_loss,
   RANK() OVER (PARTITION BY s_store_name ORDER BY (catalog_net_loss + store_net_loss) DESC) AS loss_rank
FROM combined
ORDER BY total_net_loss DESC, loss_rank
LIMIT 100
