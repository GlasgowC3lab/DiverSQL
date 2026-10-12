/*
  Goal: Analyze the combined impact of catalog returns, web returns and store sales for each product, 
  enriched with catalog page, shipping mode, customer and store attributes, while also showing inventory
  availability. The query filters on a specific year, brand, shipping type, preferred customers, education
  level, state and web site country, and keeps only rows where the refunded customer has at least one
  matching store‑sale record (correlated EXISTS). Results are aggregated per product and ordered by the
  total return amount.
*/
WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk = (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date = DATE '2001-01-01'
    )
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    sm.sm_type AS ship_mode_type,
    cp.cp_department,
    d_ret.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MAX(i.i_current_price) AS max_current_price,
    MIN(inv_agg.total_qty_on_hand) AS min_qty_on_hand,
    AVG(cd_ref.cd_purchase_estimate) AS avg_purchase_estimate
FROM inv_agg
FULL OUTER JOIN item i
    ON inv_agg.inv_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
LEFT JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
LEFT JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
LEFT JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_web_ret
    ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE
    d_ret.d_year = 2001
    AND i.i_brand = 'callyeingeing'
    AND sm.sm_type = 'STANDARD'
    AND c_ref.c_preferred_cust_flag = 'Y'
    AND cd_ref.cd_education_status = 'Advanced Degree'
    AND s.s_state = 'CA'
    AND ws.web_country = 'United States'
    AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c_ref.c_customer_sk
          AND ss2.ss_sold_date_sk = d_ret.d_date_sk
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    sm.sm_type,
    cp.cp_department,
    d_ret.d_year
ORDER BY total_return_amount DESC
LIMIT 100
