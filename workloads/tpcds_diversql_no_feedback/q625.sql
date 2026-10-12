WITH joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        d.d_date,
        d.d_year,
        t.t_hour,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_name,
        cp.cp_description,
        r_cr.r_reason_desc AS cr_reason,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_url,
        r_wr.r_reason_desc AS wr_reason
    FROM item i
    RIGHT OUTER JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
       AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
       AND d.d_date_sk = cr.cr_returned_date_sk
       AND t.t_time_sk = cr.cr_returned_time_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
       AND d.d_date_sk = wr.wr_returned_date_sk
       AND t.t_time_sk = wr.wr_returned_time_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100
      AND ca.ca_state = 'CA'
      AND (ss.ss_quantity > 0 OR cr.cr_return_quantity > 0)
)
SELECT
    jd.i_item_id,
    jd.i_product_name,
    jd.d_date,
    jd.d_year,
    jd.ca_state,
    SUM(jd.ss_quantity) AS total_quantity_sold,
    SUM(jd.ss_net_profit) AS total_net_profit,
    AVG(jd.i_current_price) AS avg_price,
    CASE WHEN SUM(jd.ss_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY jd.i_item_id ORDER BY SUM(jd.ss_net_profit) DESC) AS profit_rank
FROM joined_data jd
WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr_check
        WHERE cr_check.cr_item_sk = jd.i_item_sk
          AND cr_check.cr_return_amount > 0
    )
GROUP BY jd.i_item_id, jd.i_product_name, jd.d_date, jd.d_year, jd.ca_state
ORDER BY profit_rank, jd.d_date
