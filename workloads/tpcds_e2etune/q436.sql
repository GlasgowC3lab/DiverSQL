WITH aggregated AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        SUM(cs.cs_ext_sales_price) - SUM(COALESCE(cr.cr_return_amount, 0)) AS net_revenue,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM
        catalog_sales cs
    JOIN
        item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN
        customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN
        household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN
        catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND (cr.cr_fee > 20.0 OR cr.cr_fee IS NULL)
    WHERE
        cs.cs_quantity > 0
    GROUP BY
        i.i_category,
        hd.hd_income_band_sk
    HAVING
        SUM(cs.cs_ext_sales_price) > 1000
)
SELECT
    i_category,
    hd_income_band_sk,
    total_sales,
    total_returns,
    net_revenue,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY net_revenue DESC) AS revenue_rank
FROM
    aggregated
ORDER BY
    net_revenue DESC
LIMIT 100
