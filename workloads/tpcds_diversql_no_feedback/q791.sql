WITH promo_diff AS (
        SELECT ss.ss_promo_sk AS promo_sk
        FROM store_sales ss
        EXCEPT
        SELECT cs.cs_promo_sk
        FROM catalog_sales cs
    ),
    joined_data AS (
        SELECT
            s.s_store_id               AS s_store_id,
            p.p_promo_name             AS p_promo_name,
            ss.ss_net_profit           AS ss_net_profit,
            ss.ss_quantity             AS ss_quantity,
            cd_ss.cd_credit_rating     AS cd_credit_rating,
            hd_bill.hd_income_band_sk  AS hd_income_band_sk,
            ib.ib_lower_bound          AS ib_lower_bound,
            ca_bill.ca_state           AS ca_state,
            wp.wp_type                 AS wp_type,
            web.web_name               AS web_name,
            cs.cs_ext_ship_cost        AS cs_ext_ship_cost,
            ws.ws_net_paid_inc_tax     AS ws_net_paid_inc_tax
        FROM store_sales ss
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p
          ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd_ss
          ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_bill
          ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
        JOIN income_band ib
          ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca_bill
          ON ss.ss_addr_sk = ca_bill.ca_address_sk
        JOIN catalog_sales cs
          ON cs.cs_bill_cdemo_sk = cd_ss.cd_demo_sk
         AND cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
         AND cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN promotion p2                     -- second use of promotion table
          ON cs.cs_promo_sk = p2.p_promo_sk
        JOIN web_sales ws
          ON ws.ws_bill_cdemo_sk = cd_ss.cd_demo_sk
         AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
         AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN web_page wp
          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site web
          ON ws.ws_web_site_sk = web.web_site_sk
        JOIN promo_diff pd
          ON ss.ss_promo_sk = pd.promo_sk
        -- reuse of dimension tables for a second role
        JOIN customer_demographics cd_ws
          ON ws.ws_ship_cdemo_sk = cd_ws.cd_demo_sk
        JOIN household_demographics hd_ws
          ON ws.ws_ship_hdemo_sk = hd_ws.hd_demo_sk
        JOIN income_band ib_ws
          ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
        JOIN customer_address ca_ws
          ON ws.ws_ship_addr_sk = ca_ws.ca_address_sk
    ),
    agg AS (
        SELECT
            s_store_id,
            p_promo_name,
            SUM(ss_net_profit) AS total_net_profit
        FROM joined_data
        GROUP BY ROLLUP (s_store_id, p_promo_name)
    ),
    ranked AS (
        SELECT
            s_store_id,
            p_promo_name,
            total_net_profit,
            ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS rnk
        FROM agg
    )
SELECT
    s_store_id,
    p_promo_name,
    total_net_profit,
    rnk
FROM ranked
WHERE rnk <= 3               -- top‑3 promotions per store
   OR s_store_id IS NULL       -- keep grand total row
ORDER BY s_store_id,
         rnk NULLS LAST
LIMIT 100
