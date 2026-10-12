WITH joined_data AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_net_loss,
       d.d_year,
       r.r_reason_desc,
       sm.sm_type,
       cd_ref.cd_gender,
       ca_ref.ca_state,
       cs.cs_quantity,
       CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_category,
       ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY cr.cr_return_amount DESC) AS rn
   FROM catalog_returns AS cr
   JOIN catalog_sales AS cs
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim AS d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason AS r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode AS sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics AS cd_ref
     ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN household_demographics AS hd_ref
     ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN customer_address AS ca_ref
     ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN store_returns AS sr
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics AS cd_store
     ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
   JOIN household_demographics AS hd_store
     ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
   JOIN customer_address AS ca_store
     ON sr.sr_addr_sk = ca_store.ca_address_sk
   JOIN inventory AS inv
     ON inv.inv_date_sk = d.d_date_sk
   JOIN web_page AS wp
     ON wp.wp_creation_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND r.r_reason_id IN ('AAAAAAAAABAAAAAA','AAAAAAAADAAAAAAA')
     AND sm.sm_type = 'AIR'
     AND cs.cs_quantity > 2
     AND ca_ref.ca_state = 'CA'
),
high_returns AS (
   SELECT cr_order_number
   FROM joined_data
   WHERE cr_return_amount >= 100
),
low_returns AS (
   SELECT cr_order_number
   FROM joined_data
   WHERE cr_return_amount < 20
),
top_k AS (
   SELECT *
   FROM joined_data
   WHERE rn <= 3
)
SELECT
   tk.cr_order_number,
   tk.cr_return_amount,
   tk.return_category,
   tk.r_reason_desc,
   tk.rn,
   m.month_id
FROM top_k AS tk
CROSS JOIN (
   SELECT * FROM (VALUES (1), (2), (3)) AS t(month_id)
) AS m
WHERE tk.cr_order_number IN (
   SELECT cr_order_number FROM high_returns
   EXCEPT
   SELECT cr_order_number FROM low_returns
)
ORDER BY tk.cr_return_amount DESC, m.month_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
