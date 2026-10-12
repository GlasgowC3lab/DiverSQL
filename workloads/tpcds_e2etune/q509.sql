WITH promo_inventory AS (
    SELECT
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
        COUNT(DISTINCT c.c_customer_id) AS num_customers_targeted,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM
        inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
            AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        LEFT JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        p.p_discount_active = 'Y'
        AND i.i_category = 'Electronics'
    GROUP BY
        i.i_brand,
        d.d_year,
        d.d_month_seq
)
SELECT
    i_brand,
    d_year,
    d_month_seq,
    total_inventory_value,
    num_customers_targeted,
    avg_income_band,
    RANK() OVER (PARTITION BY d_year ORDER BY total_inventory_value DESC) AS brand_year_rank
FROM
    promo_inventory
ORDER BY
    total_inventory_value DESC
LIMIT 100
