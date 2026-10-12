WITH sales_by_store AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_wholesale_cost) AS avg_wholesale_cost
    FROM tpcds.store_sales
    WHERE ss_wholesale_cost > 40.00
      AND ss_coupon_amt < 500.00
      AND ss_quantity >= 1
      AND ss_store_sk IN (SELECT s_store_sk FROM tpcds.store WHERE s_division_id = 1)
    GROUP BY ss_store_sk
    HAVING SUM(ss_net_paid) > 100000
)
SELECT
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    st.s_tax_percentage,
    sb.total_sales,
    sb.total_profit,
    sb.total_quantity,
    sb.avg_wholesale_cost,
    CASE WHEN sb.total_profit / NULLIF(sb.total_sales, 0) > 0.20 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY st.s_state ORDER BY sb.total_sales DESC) AS sales_rank_state,
    ROW_NUMBER() OVER (ORDER BY sb.total_sales DESC) AS overall_rank
FROM sales_by_store sb
JOIN tpcds.store st ON st.s_store_sk = sb.ss_store_sk
WHERE st.s_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
  AND st.s_closed_date_sk IN (2450859, 2451014)
  AND st.s_tax_percentage < 0.07
ORDER BY overall_rank
LIMIT 100
