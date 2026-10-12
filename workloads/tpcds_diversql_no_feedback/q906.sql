-- goal: Identify the top‑performing stores in 2000 (CA) by total net profit, excluding customers who have high‑quantity returns, and show their rank.
WITH base AS (
    SELECT
        s.s_store_id,
        d_year.d_year,
        ss.ss_net_profit               AS store_profit,
        sr.sr_net_loss                 AS return_loss,
        cs.cs_net_profit               AS catalog_profit,
        cust.c_customer_sk,
        cust.c_birth_country,
        s.s_state,
        p.p_discount_active,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca_bill.ca_address_sk          AS bill_address_sk,
        ca_ship.ca_address_sk          AS ship_address_sk,
        t_cs.t_hour                    AS sale_hour,
        r.r_reason_desc                AS return_reason
    FROM catalog_sales cs
    JOIN date_dim d_year            ON cs.cs_sold_date_sk   = d_year.d_date_sk
    JOIN time_dim t_cs              ON cs.cs_sold_time_sk   = t_cs.t_time_sk
    JOIN customer cust              ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca_bill   ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
    JOIN customer_address ca_ship   ON cs.cs_ship_addr_sk   = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib            ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p               ON cs.cs_promo_sk      = p.p_promo_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
    JOIN store_sales ss            ON ss.ss_ticket_number = cs.cs_order_number
    JOIN store s                   ON ss.ss_store_sk      = s.s_store_sk
    JOIN date_dim d_store_closed   ON s.s_closed_date_sk  = d_store_closed.d_date_sk
    JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_return         ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_ret   ON sr.sr_addr_sk       = ca_ret.ca_address_sk
    JOIN reason r                  ON sr.sr_reason_sk    = r.r_reason_sk
    JOIN web_page wp               ON wp.wp_customer_sk  = cust.c_customer_sk
    JOIN date_dim d_wp_creation    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access      ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
    JOIN web_site ws               ON ws.web_open_date_sk   = d_wp_creation.d_date_sk
    JOIN date_dim d_ws_close       ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_year.d_year = 2000
      AND s.s_state = 'CA'
      AND cust.c_birth_country = 'PHILIPPINES'
)
SELECT
    base.s_store_id,
    base.d_year,
    SUM(base.store_profit) AS total_store_profit,
    ROW_NUMBER() OVER (PARTITION BY base.d_year ORDER BY SUM(base.store_profit) DESC) AS profit_rank
FROM base
WHERE base.c_customer_sk NOT IN (
    SELECT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 5
)
GROUP BY base.s_store_id, base.d_year
ORDER BY total_store_profit DESC
LIMIT 100
