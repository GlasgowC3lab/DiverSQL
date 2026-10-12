/*
Goal: Identify top customer‑day‑product‑promotion combinations by net sales, enriched with demographic, warehouse and promotion information, while demonstrating advanced SQL features such as CASE, anti‑semi join, FULL OUTER JOIN, window functions, DISTINCT aggregates and correlated subqueries.
*/
WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d_sold.d_date           AS cs_sold_date,
        d_ship.d_date           AS cs_ship_date,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        p.p_promo_name,
        p.p_start_date_sk,
        hd_bill.hd_buy_potential,
        c.c_customer_id,
        cs.cs_quantity,
        cs.cs_net_paid,
        ib.ib_lower_bound,
        t_sold.t_hour,
        ws.ws_web_site_sk,
        ws_site.web_name,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        r.r_reason_desc,
        (
            SELECT SUM(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_order_number = cs.cs_order_number
        ) AS total_return_amount
    FROM catalog_sales cs
    JOIN date_dim d_sold                ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN date_dim d_ship                ON cs.cs_ship_date_sk   = d_ship.d_date_sk
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion p                   ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c                    ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN income_band ib           ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN time_dim t_sold          ON cs.cs_sold_time_sk   = t_sold.t_time_sk
    LEFT JOIN web_sales ws             ON cs.cs_order_number   = ws.ws_order_number
    LEFT JOIN web_site ws_site          ON ws.ws_web_site_sk    = ws_site.web_site_sk
    LEFT JOIN web_returns wr           ON ws.ws_order_number   = wr.wr_order_number
    LEFT JOIN reason r                 ON wr.wr_reason_sk      = r.r_reason_sk
),
agg AS (
    SELECT
        b.c_customer_id,
        b.cs_sold_date,
        b.cp_department,
        b.sm_type,
        b.w_warehouse_name,
        b.p_promo_name,
        b.p_start_date_sk,
        CASE WHEN b.hd_buy_potential = '0-500' THEN 'Low' ELSE 'Other' END AS buy_potential_category,
        COUNT(DISTINCT b.cs_order_number)           AS distinct_orders,
        SUM(DISTINCT b.cs_quantity)                 AS distinct_quantity_sum,
        SUM(b.cs_net_paid)                          AS total_net_paid,
        SUM(b.total_return_amount)                  AS total_returns_amount
    FROM base b
    WHERE b.cs_order_number NOT IN (
        SELECT wr3.wr_order_number FROM web_returns wr3
    )
    GROUP BY
        b.c_customer_id,
        b.cs_sold_date,
        b.cp_department,
        b.sm_type,
        b.w_warehouse_name,
        b.p_promo_name,
        b.p_start_date_sk,
        b.hd_buy_potential
)
SELECT
    a.c_customer_id,
    a.cs_sold_date,
    a.cp_department,
    a.sm_type,
    a.w_warehouse_name,
    a.p_promo_name,
    a.buy_potential_category,
    a.distinct_orders,
    a.distinct_quantity_sum,
    a.total_net_paid,
    a.total_returns_amount,
    LAG(a.total_net_paid) OVER (PARTITION BY a.c_customer_id ORDER BY a.cs_sold_date) AS prev_total_net_paid
FROM agg a
FULL OUTER JOIN date_dim d_promo_start
    ON a.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN customer cust2
    ON a.c_customer_id = cust2.c_customer_id
ORDER BY a.total_net_paid DESC
LIMIT 100
