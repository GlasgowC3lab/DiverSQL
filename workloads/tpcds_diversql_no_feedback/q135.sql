WITH joined_data AS (
    SELECT
        s.s_store_name,
        p.p_promo_name,
        cp.cp_catalog_page_number,
        d_ss.d_date,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_profit AS cs_net_profit
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib_hd_ss
        ON hd_ss.hd_income_band_sk = ib_hd_ss.ib_income_band_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib_hd_bill
        ON hd_bill.hd_income_band_sk = ib_hd_bill.ib_income_band_sk
    WHERE d_ss.d_fy_year = 1914
      AND p.p_channel_press = 'N'
),
aggregated AS (
    SELECT
        s_store_name,
        p_promo_name,
        cp_catalog_page_number,
        d_date,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ss_net_profit) + SUM(cs_net_profit) AS total_net_profit
    FROM joined_data
    GROUP BY
        s_store_name,
        p_promo_name,
        cp_catalog_page_number,
        d_date
    HAVING SUM(ss_net_profit) + SUM(cs_net_profit) > 10000
)
SELECT
    s_store_name,
    p_promo_name,
    cp_catalog_page_number,
    d_date,
    total_store_profit,
    total_catalog_profit,
    total_net_profit,
    LAG(total_net_profit) OVER (PARTITION BY s_store_name ORDER BY d_date) AS prior_day_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
