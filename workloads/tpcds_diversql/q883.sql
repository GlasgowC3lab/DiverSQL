WITH agg AS (
    SELECT
        d_sold.d_year AS sale_year,
        sm.sm_type,
        CASE WHEN hd_bill.hd_income_band_sk > 10 THEN 'High' ELSE 'Low' END AS income_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold      ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN date_dim d_ship      ON cs.cs_ship_date_sk   = d_ship.d_date_sk
    JOIN time_dim t           ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN ship_mode sm        ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN promotion p         ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN date_dim d_start    ON p.p_start_date_sk    = d_start.d_date_sk
    JOIN date_dim d_end      ON p.p_end_date_sk      = d_end.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND hd_bill.hd_income_band_sk BETWEEN 7 AND 15
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
      AND cs.cs_order_number NOT IN (
            SELECT cs2.cs_order_number
            FROM catalog_sales cs2
            WHERE cs2.cs_quantity = 0
        )
    GROUP BY d_sold.d_year,
             sm.sm_type,
             CASE WHEN hd_bill.hd_income_band_sk > 10 THEN 'High' ELSE 'Low' END
)
SELECT DISTINCT
    sale_year,
    sm_type,
    income_category,
    total_net_paid,
    distinct_orders,
    RANK() OVER (PARTITION BY sale_year ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
ORDER BY sale_year ASC, sales_rank ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
