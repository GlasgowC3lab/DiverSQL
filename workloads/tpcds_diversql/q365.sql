WITH eligible_customers AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
    EXCEPT
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 200000
),
sales_agg AS (
    SELECT
        cp.cp_department AS cp_department,
        i.i_brand AS i_brand,
        ib.ib_income_band_sk AS ib_income_band_sk,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN eligible_customers ec ON cs.cs_bill_customer_sk = ec.cust_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_brand = 'BrandX'
      AND ib.ib_upper_bound <= 150000
      AND cs.cs_quantity > 0
    GROUP BY cp.cp_department, i.i_brand, ib.ib_income_band_sk
)
SELECT
    sales_agg.cp_department,
    sales_agg.i_brand,
    sales_agg.ib_income_band_sk,
    sales_agg.unique_customers,
    sales_agg.total_sales,
    sales_agg.total_profit,
    CASE WHEN sales_agg.total_profit > 5000 THEN 'High' ELSE 'Low' END AS profit_category,
    sales_agg.total_sales / NULLIF(sales_agg.unique_customers, 0) AS avg_sales_per_customer
FROM sales_agg
WHERE sales_agg.total_sales > 10000
ORDER BY sales_agg.total_profit DESC, sales_agg.cp_department
LIMIT 100
