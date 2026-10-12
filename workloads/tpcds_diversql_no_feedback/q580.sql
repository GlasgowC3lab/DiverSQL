WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
            AND ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_state = 'CA'
        AND hd.hd_buy_potential = '1001-5000'
        AND p.p_channel_email = 'Y'
        AND s.s_state = 'CA'
        AND wp.wp_type = 'article'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year
)
SELECT
    c_customer_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    s_store_id,
    s_store_name,
    p_promo_name,
    d_year,
    total_net_paid,
    total_catalog_net_paid,
    total_store_net_paid,
    catalog_order_cnt,
    store_ticket_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS store_rank,
    LAG(total_net_paid) OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS prev_store_total_net_paid
FROM
    sales_agg
ORDER BY
    total_net_paid DESC
LIMIT 100
