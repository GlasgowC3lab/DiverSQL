WITH
    sampled_catalog AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
        WHERE cs_sold_date_sk > 2450000
    ),
    customer_base AS (
        SELECT c.c_customer_sk,
               c.c_customer_id,
               c.c_first_name,
               c.c_last_name,
               ca.ca_state,
               ca.ca_city,
               hd.hd_income_band_sk,
               hd.hd_buy_potential
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        WHERE ca.ca_state = 'CA' AND hd.hd_income_band_sk = 5
    ),
    catalog_join AS (
        SELECT sc.cs_order_number,
               sc.cs_net_paid,
               sc.cs_net_profit,
               sc.cs_ship_mode_sk,
               sc.cs_bill_customer_sk,
               sc.cs_sold_date_sk
        FROM sampled_catalog sc
    ),
    ship_mode_full AS (
        SELECT sm.sm_ship_mode_sk,
               sm.sm_contract
        FROM ship_mode sm
        FULL OUTER JOIN catalog_join cj ON sm.sm_ship_mode_sk = cj.cs_ship_mode_sk
    ),
    store_sales_join AS (
        SELECT ss.ss_ticket_number,
               ss.ss_quantity,
               ss.ss_customer_sk
        FROM store_sales ss
        WHERE ss.ss_quantity > 1
    ),
    store_returns_join AS (
        SELECT sr.sr_return_quantity,
               sr.sr_ticket_number
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
    ),
    web_sales_join AS (
        SELECT ws.ws_order_number,
               ws.ws_net_paid,
               ws.ws_ship_mode_sk,
               ws.ws_web_page_sk,
               ws.ws_web_site_sk,
               ws.ws_bill_customer_sk,
               ws.ws_net_profit
        FROM web_sales ws
        WHERE ws.ws_net_paid > 0
    ),
    web_returns_join AS (
        SELECT wr.wr_order_number,
               wr.wr_refunded_customer_sk
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 0
    ),
    web_page_join AS (
        SELECT wp.wp_web_page_sk,
               wp.wp_char_count,
               wp.wp_rec_end_date
        FROM web_page wp
        WHERE wp.wp_char_count > 3000
    ),
    web_site_join AS (
        SELECT ws.web_site_sk,
               ws.web_state
        FROM web_site ws
        WHERE ws.web_state = 'CA'
    ),
    union_customers AS (
        SELECT c_customer_sk FROM customer_base
        UNION
        SELECT cs_bill_customer_sk FROM catalog_join
    ),
    intersect_keys AS (
        SELECT c_customer_sk FROM customer_base
        INTERSECT
        SELECT cs_bill_customer_sk FROM catalog_join
    ),
    except_keys AS (
        SELECT c_customer_sk FROM customer_base
        EXCEPT
        SELECT wr_refunded_customer_sk FROM web_returns_join
    )
SELECT
    cb.c_customer_id,
    cb.c_first_name,
    cb.c_last_name,
    cb.ca_city,
    cb.hd_buy_potential,
    cj.cs_net_paid,
    smf.sm_contract,
    wsj.ws_net_paid,
    wpj.wp_char_count,
    ROW_NUMBER() OVER (PARTITION BY cb.c_customer_sk ORDER BY cj.cs_net_paid DESC) AS rn,
    RANK() OVER (PARTITION BY cb.c_customer_sk ORDER BY wsj.ws_net_paid DESC) AS profit_rank,
    CASE WHEN cj.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM customer_base cb
JOIN catalog_join cj ON cb.c_customer_sk = cj.cs_bill_customer_sk
LEFT JOIN ship_mode_full smf ON cj.cs_ship_mode_sk = smf.sm_ship_mode_sk
JOIN store_sales_join ssj ON cb.c_customer_sk = ssj.ss_customer_sk
JOIN store_returns_join srj ON ssj.ss_ticket_number = srj.sr_ticket_number
JOIN web_sales_join wsj ON cb.c_customer_sk = wsj.ws_bill_customer_sk
JOIN web_page_join wpj ON wsj.ws_web_page_sk = wpj.wp_web_page_sk
JOIN web_site_join wsite ON wsj.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns_join wrj ON wsj.ws_order_number = wrj.wr_order_number
WHERE wpj.wp_rec_end_date = DATE '2000-09-02'
  AND EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.c_customer_sk = cb.c_customer_sk)
  AND NOT EXISTS (SELECT 1 FROM except_keys ek WHERE ek.c_customer_sk = cb.c_customer_sk)
  AND cb.c_customer_sk IN (SELECT c_customer_sk FROM union_customers)
ORDER BY cj.cs_net_paid DESC
LIMIT 100
