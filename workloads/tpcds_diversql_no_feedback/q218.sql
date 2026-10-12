WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_brand,
        cc.cc_market_manager,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        sr.sr_return_amt,
        cs.cs_sales_price,
        cs.cs_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND c.c_birth_month = 6
      AND cc.cc_market_manager = 'John Doe'
      AND wp.wp_max_ad_count = 2
)
SELECT
    d_year,
    s_state,
    i_brand,
    cc_market_manager,
    COUNT(DISTINCT ss_ticket_number) AS num_sales,
    SUM(ss_net_paid) AS total_sales,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(cs_sales_price) AS avg_catalog_sales_price,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM base
GROUP BY d_year, s_state, i_brand, cc_market_manager
HAVING SUM(ss_net_paid) > 10000
   AND COUNT(DISTINCT ss_ticket_number) > 10
LIMIT 100
