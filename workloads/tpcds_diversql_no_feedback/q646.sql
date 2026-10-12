WITH sales_data AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        cs.cs_ext_sales_price AS cs_rev,
        ss.ss_ext_sales_price AS ss_rev
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer cust_store
        ON ss.ss_customer_sk = cust_store.c_customer_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    WHERE
        d.d_year = 2002
        AND s.s_floor_space > 8000000
        AND i.i_current_price > 100
        AND cd_bill.cd_gender = 'M'
        AND hd_bill.hd_income_band_sk IN (1, 2)
        AND cs.cs_ext_ship_cost > 500
        AND sm.sm_carrier = 'UPS'
),
agg AS (
    SELECT
        year,
        s_store_name,
        i_category,
        SUM(cs_rev) AS catalog_rev,
        SUM(ss_rev) AS store_rev,
        SUM(cs_rev) + SUM(ss_rev) AS total_rev
    FROM sales_data
    GROUP BY year, s_store_name, i_category
    HAVING SUM(cs_rev) + SUM(ss_rev) > 100000
)
SELECT
    year,
    s_store_name,
    i_category,
    catalog_rev,
    store_rev,
    total_rev,
    RANK() OVER (PARTITION BY year ORDER BY total_rev DESC) AS revenue_rank
FROM agg
ORDER BY year, revenue_rank
LIMIT 100
