WITH joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        s.s_store_id,
        s.s_state,
        c.c_customer_id,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        sm.sm_carrier,
        i.inv_quantity_on_hand,
        wp.wp_char_count,
        ws.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.store s
        ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN tpcds.reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_market_manager LIKE '%Smith%'
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
      AND sm.sm_carrier = 'UPS'
)
SELECT
    s_store_id,
    d_date,
    total_sales,
    cumulative_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        s_store_id,
        d_date,
        SUM(cs_net_paid) AS total_sales,
        SUM(SUM(cs_net_paid)) OVER (PARTITION BY s_store_id ORDER BY d_date
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM joined_data
    GROUP BY s_store_id, d_date
) agg
WHERE s_store_id NOT IN (
    SELECT s.s_store_id
    FROM tpcds.store s
    WHERE s.s_city = 'UnknownCity'
)
ORDER BY sales_rank
LIMIT 100
