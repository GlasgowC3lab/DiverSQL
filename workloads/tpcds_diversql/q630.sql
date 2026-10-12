WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
-- Join all tables and compute a correlated scalar sub‑query per customer
customer_combined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d_sold.d_date,
        ss.ss_sold_time_sk,
        t.t_hour,
        ss.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ss.ss_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_call_center_sk,
        cc.cc_name,
        cs.cs_catalog_page_sk,
        cp.cp_type,
        ws.web_name,
        rs.r_reason_desc,
        -- correlated scalar: total catalog sales for this customer
        (SELECT SUM(cs3.cs_ext_sales_price)
         FROM catalog_sales cs3
         WHERE cs3.cs_bill_customer_sk = ss.ss_customer_sk) AS cust_total_catalog_sales
    FROM sampled_store_sales ss
    JOIN date_dim d_sold               ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t                    ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c                    ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd    ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason rs               ON sr.sr_reason_sk = rs.r_reason_sk
    LEFT JOIN catalog_sales cs        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_site ws             ON cc.cc_open_date_sk = ws.web_open_date_sk
    WHERE d_sold.d_year = 2001                               -- filter 1
      AND cc.cc_market_manager = 'John Doe'                  -- filter 2
      AND ws.web_country = 'United States'                   -- filter 3
      AND rs.r_reason_desc LIKE '%customer%'                 -- filter 4
      AND ib.ib_upper_bound > 50000                          -- filter 5
),
-- Set of ticket numbers that appear in store_sales but not in store_returns
tickets_without_return AS (
    SELECT ARRAY_AGG(tn) AS ticket_list
    FROM (
        SELECT ss2.ss_ticket_number AS tn
        FROM store_sales ss2
        EXCEPT
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
    ) x
)
SELECT
    cc_comb.ss_ticket_number,
    cc_comb.d_date,
    cc_comb.c_first_name,
    cc_comb.c_last_name,
    cc_comb.cc_name,
    cc_comb.cp_type,
    cc_comb.web_name,
    CASE
        WHEN cc_comb.ss_net_paid > 1000 THEN 'HIGH'
        WHEN cc_comb.ss_net_paid BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category,
    cc_comb.cust_total_catalog_sales,
    RANK() OVER (PARTITION BY cc_comb.ss_customer_sk ORDER BY cc_comb.ss_net_paid DESC) AS sales_rank,
    twr.ticket_list AS tickets_without_return
FROM customer_combined cc_comb
JOIN tickets_without_return twr ON TRUE
WHERE cc_comb.ss_ticket_number IN (
    SELECT ss3.ss_ticket_number
    FROM store_sales ss3
    WHERE ss3.ss_quantity > 5
)   -- IN sub‑query filter
ORDER BY cc_comb.ss_net_paid DESC
LIMIT 100
