WITH base AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        CASE WHEN cc.cc_class = 'large' THEN 'L' ELSE 'S' END AS cc_size_flag,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_total,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS inventory_qty,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        (SELECT MAX(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk) AS max_cc_sales,
        cc.cc_call_center_sk                     -- needed for the scalar sub‑query, not projected further
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_gmt_offset > -5.00
      AND cc.cc_tax_percentage < 10.00
      AND cust.c_birth_country IN ('SWITZERLAND', 'GAMBIA', 'TOGO')
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = 'HIGH'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY
        cc.cc_call_center_id,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cc.cc_class,
        cc.cc_call_center_sk
)
-- First UNION branch (high total sales)
, union_branch AS (
    SELECT
        cc_call_center_id,
        d_year,
        cc_size_flag,
        total_sales,
        store_sales_total,
        inventory_qty,
        distinct_orders,
        max_cc_sales
    FROM base
    WHERE total_sales > 10000
    UNION DISTINCT
    SELECT
        cc_call_center_id,
        d_year,
        cc_size_flag,
        total_sales,
        store_sales_total,
        inventory_qty,
        distinct_orders,
        max_cc_sales
    FROM base
    WHERE store_sales_total > 5000
)
-- Second sub‑query used for INTERSECT (sufficient inventory)
, intersect_branch AS (
    SELECT
        cc_call_center_id,
        d_year,
        cc_size_flag,
        total_sales,
        store_sales_total,
        inventory_qty,
        distinct_orders,
        max_cc_sales
    FROM base
    WHERE inventory_qty > 100
)
SELECT *
FROM (
    SELECT * FROM union_branch
    INTERSECT
    SELECT * FROM intersect_branch
) final_set
ORDER BY total_sales DESC
OFFSET 20 ROWS FETCH NEXT 100 ROWS ONLY
