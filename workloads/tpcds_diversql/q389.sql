/*
Goal: Produce a deep‑join analytical view that combines catalog sales, web sales and returns with all supporting dimension tables, samples the sales fact, classifies rows with a CASE expression, aggregates sales totals, de‑duplicates via UNION, limits to orders that appear in two independent filters via INTERSECT, and returns the top 100 orders by total sales.
*/
WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample roughly 10% of catalog_sales rows
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_coupon_amt,
        ws.ws_ext_sales_price   AS ws_ext_sales_price,
        d1.d_year,
        i.i_category,
        sm.sm_type,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        CASE WHEN cs.cs_coupon_amt > 0 THEN 'Coupon' ELSE 'NoCoupon' END AS coupon_flag,
        r.r_reason_desc,
        s.s_store_name,
        wp.wp_type,
        wsite.web_name
    FROM sampled_sales cs
    -- chain of joins (left‑deep)
    JOIN date_dim d1               ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_start          ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end            ON cp.cp_end_date_sk   = d_end.d_date_sk
    JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s                   ON s.s_closed_date_sk = d1.d_date_sk
    JOIN web_sales ws              ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite            ON wsite.web_open_date_sk = d1.d_date_sk
    JOIN web_returns wr            ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r                  ON wr.wr_reason_sk = r.r_reason_sk
),
-- First analytical branch: catalog‑sales based aggregation
catalog_agg AS (
    SELECT
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        coupon_flag
    FROM joined_data
    GROUP BY cs_order_number, coupon_flag
),
-- Second analytical branch: web‑sales based aggregation
web_agg AS (
    SELECT
        cs_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        'Web' AS coupon_flag
    FROM joined_data
    GROUP BY cs_order_number
),
-- Union of the two branches (deduplicated by UNION DISTINCT)
union_agg AS (
    SELECT * FROM catalog_agg
    UNION
    SELECT * FROM web_agg
),
-- Keys that satisfy two independent filters – intersected
intersect_keys AS (
    SELECT cs_order_number FROM joined_data WHERE d_year = 2001
    INTERSECT
    SELECT cs_order_number FROM joined_data WHERE i_category = 'Electronics'
)
SELECT
    u.cs_order_number,
    u.total_sales,
    u.coupon_flag
FROM union_agg u
JOIN intersect_keys ik ON u.cs_order_number = ik.cs_order_number
ORDER BY u.total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
