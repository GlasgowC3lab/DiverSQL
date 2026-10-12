WITH joined_data AS (
    SELECT
        d_sold.d_year AS d_year,
        r.r_reason_desc AS r_reason_desc,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_sales_price AS cs_sales_price,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        cs.cs_wholesale_cost AS cs_wholesale_cost,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        cs.cs_quantity AS cs_quantity,
        wp.wp_max_ad_count AS wp_max_ad_count
    FROM
        date_dim d_sold
        JOIN catalog_sales cs
          ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_cs
          ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN customer_demographics cd_bill
          ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_address ca_bill
          ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_ship
          ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN customer_address ca_ship
          ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_returned_date_sk = d_sold.d_date_sk
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        JOIN store_sales ss
          ON ss.ss_item_sk = cs.cs_item_sk
         AND ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN customer_demographics cd_ss
          ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN customer_address ca_ss
          ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN store_returns sr
          ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_returned_date_sk = d_sold.d_date_sk
         AND sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd_sr
          ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN customer_address ca_sr
          ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN web_returns wr
          ON wr.wr_returned_date_sk = d_sold.d_date_sk
         AND wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp
          ON wp.wp_web_page_sk = wr.wr_web_page_sk
        JOIN time_dim t_wr
          ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN customer_demographics cd_wr_refunded
          ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
        JOIN customer_address ca_wr_refunded
          ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
        JOIN customer_demographics cd_wr_returning
          ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
        JOIN customer_address ca_wr_returning
          ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
        JOIN time_dim t_cr
          ON cr.cr_returned_time_sk = t_cr.t_time_sk
        JOIN time_dim t_sr
          ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN date_dim d_wp_create
          ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
        JOIN date_dim d_wp_access
          ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE
        d_sold.d_year = 2002
        AND cs.cs_wholesale_cost > 30
        AND r.r_reason_desc = 'Damaged'
        AND EXISTS (
            SELECT 1 FROM store_sales ss2
            WHERE ss2.ss_item_sk = cs.cs_item_sk
              AND ss2.ss_sold_date_sk = d_sold.d_date_sk
        )
)
SELECT
    d_year,
    r_reason_desc,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_sales_price) AS avg_sales_price,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(cs_quantity) AS total_quantity_sold,
    AVG(cs_ext_discount_amt) AS avg_discount_amount,
    MAX(wp_max_ad_count) AS max_ad_count_on_page
FROM joined_data
GROUP BY d_year, r_reason_desc
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
