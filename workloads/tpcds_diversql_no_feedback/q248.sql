WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_discount_active,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        i.inv_quantity_on_hand,
        cc.cc_name,
        cp.cp_type,
        ws.ws_order_number,
        wr.wr_return_amt,
        r.r_reason_desc
    FROM store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
),
store_year_sales AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY s_store_id, s_store_name, d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_net_paid,
    total_sales,
    txn_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank
FROM store_year_sales
ORDER BY d_year, sales_rank
LIMIT 100
