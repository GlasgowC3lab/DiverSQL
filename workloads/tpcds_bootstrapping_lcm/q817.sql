WITH inventory_by_date AS (
    SELECT
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_date
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_date
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
),
call_center_info AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_tax_percentage,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_date
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_email_address,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_date
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
base AS (
    SELECT
        ibd.d_year,
        si.s_store_id,
        si.s_store_name,
        cci.cc_name,
        COUNT(DISTINCT ci.c_customer_id) AS distinct_customers,
        SUM(ibd.inv_quantity_on_hand) AS total_inventory_qty,
        AVG(si.s_tax_percentage) AS avg_store_tax,
        AVG(cci.cc_tax_percentage) AS avg_call_center_tax,
        MIN(ibd.d_date) AS earliest_inventory_date,
        MAX(ibd.d_date) AS latest_inventory_date
    FROM inventory_by_date ibd
    JOIN store_info si ON ibd.d_date_sk = si.d_date_sk
    JOIN call_center_info cci ON ibd.d_date_sk = cci.d_date_sk
    JOIN customer_info ci ON ibd.d_date_sk = ci.d_date_sk
    WHERE ibd.inv_quantity_on_hand > 0
      AND si.s_state = 'TX'
      AND cci.cc_state = 'TX'
    GROUP BY
        ibd.d_year,
        si.s_store_id,
        si.s_store_name,
        cci.cc_name
    HAVING SUM(ibd.inv_quantity_on_hand) > 1000
)
SELECT
    b.d_year,
    b.s_store_id,
    b.s_store_name,
    b.cc_name,
    b.distinct_customers,
    b.total_inventory_qty,
    b.avg_store_tax,
    b.avg_call_center_tax,
    b.earliest_inventory_date,
    b.latest_inventory_date,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_inventory_qty DESC) AS inventory_rank_by_year
FROM base b
ORDER BY b.d_year DESC, inventory_rank_by_year ASC
