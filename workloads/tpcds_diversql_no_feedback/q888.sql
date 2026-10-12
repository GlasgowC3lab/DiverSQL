WITH base AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON d.d_date_sk = cr.cr_returned_date_sk
    LEFT JOIN store_returns sr
        ON d.d_date_sk = sr.sr_returned_date_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND wp.wp_autogen_flag = 'N'
      AND ib.ib_lower_bound >= 90000
      AND ws.ws_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0)
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
)
SELECT
    base.d_year,
    base.cd_gender,
    base.cd_marital_status,
    base.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY base.cd_gender ORDER BY base.total_net_profit DESC) AS gender_rank
FROM base
ORDER BY base.total_net_profit DESC, base.d_year
