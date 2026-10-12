WITH base_join AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        cd.cd_credit_rating,
        ca.ca_state,
        sm.sm_type,
        wp.wp_type,
        inv.inv_quantity_on_hand,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        sr.sr_net_loss
    FROM tpcds.date_dim d
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
       AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cd.cd_credit_rating = 'Good'
      AND ws.ws_coupon_amt > 1000
      AND inv.inv_quantity_on_hand > 0
      AND ss.ss_ticket_number NOT IN (SELECT sr2.sr_ticket_number FROM tpcds.store_returns sr2)
),
agg_cube AS (
    SELECT
        d_year,
        sm_type,
        wp_type,
        SUM(ss_net_profit) AS sum_sales_profit,
        SUM(ws_net_profit) AS sum_web_profit,
        SUM(COALESCE(sr_net_loss, 0)) AS sum_return_loss,
        SUM(inv_quantity_on_hand) AS sum_inventory,
        COUNT(DISTINCT c_customer_id) AS cnt_customers
    FROM base_join
    GROUP BY CUBE (d_year, sm_type, wp_type)
)
SELECT
    d_year,
    sm_type,
    wp_type,
    sum_sales_profit,
    sum_web_profit,
    sum_return_loss,
    sum_inventory,
    cnt_customers,
    rn AS rank_in_year
FROM (
    SELECT
        d_year,
        sm_type,
        wp_type,
        sum_sales_profit,
        sum_web_profit,
        sum_return_loss,
        sum_inventory,
        cnt_customers,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_sales_profit DESC) AS rn
    FROM agg_cube
) t
WHERE rn <= 5
ORDER BY d_year, rn
