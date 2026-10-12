WITH filtered_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid_inc_ship,
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_category = 'Electronics'
      AND cd.cd_education_status = 'College'
      AND hd.hd_dep_count > 2
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_department,
    SUM(fs.cs_net_profit) AS total_net_profit,
    SUM(fs.cs_net_paid_inc_ship) AS total_sales,
    COUNT(*) AS num_sales,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.cs_bill_customer_sk) AS distinct_customers,
    RANK() OVER (ORDER BY SUM(fs.cs_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY cp.cp_catalog_page_id, cp.cp_type, cp.cp_department
HAVING SUM(fs.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
